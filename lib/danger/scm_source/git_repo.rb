# For more info see: https://github.com/schacon/ruby-git

require "git"

module Danger
  class GitRepo
    attr_accessor :diff, :log, :folder

    def diff_for_folder(folder, from: "master", to: "HEAD")
      self.folder = folder
      repo = Git.open self.folder

      ensure_commitish_exists!(from)
      ensure_commitish_exists!(to)

      merge_base = find_merge_base(repo, from, to)
      commits_in_branch_count = commits_in_branch_count(from, to)

      self.diff = repo.diff(merge_base, to)
      self.log = repo.log(commits_in_branch_count).between(from, to)
    end

    def renamed_files
      # Get raw diff with --find-renames --diff-filter
      # We need to pass --find-renames cause
      # older versions of git don't use this flag as default
      diff = exec(
        "diff #{self.diff.from} #{self.diff.to} --find-renames --diff-filter=R"
      ).lines.map { |line| line.tr("\n", "") }

      before_name_regexp = /^rename from (.*)$/
      after_name_regexp = /^rename to (.*)$/

      # Extract old and new paths via regexp
      diff.each_with_index.map do |line, index|
        before_match = line.match(before_name_regexp)
        next unless before_match

        after_match = diff.fetch(index + 1, "").match(after_name_regexp)
        next unless after_match

        {
          before: before_match.captures.first,
          after: after_match.captures.first
        }
      end.compact
    end

    def exec(string)
      require "open3"
      Dir.chdir(self.folder || ".") do
        Open3.popen2(default_env, "git #{string}") do |_stdin, stdout, _wait_thr|
          stdout.read.rstrip
        end
      end
    end

    def head_commit
      exec("rev-parse HEAD")
    end

    def origins
      exec("remote show origin -n").lines.grep(/Fetch URL/)[0].split(": ", 2)[1].chomp
    end

    def ensure_commitish_exists!(commitish)
      return ensure_commitish_exists_on_branch!(commitish, commitish) if commit_is_ref?(commitish)
      return if commit_exists?(commitish)

      git_in_depth_fetch
      raise_if_we_cannot_find_the_commit(commitish) if commit_not_exists?(commitish)
    end

    def ensure_commitish_exists_on_branch!(branch, commitish)
      return if commit_exists?(commitish)

      depth = 0
      success =
        (3..6).any? do |factor|
          depth += Math.exp(factor).to_i

          git_fetch_branch_to_depth(branch, depth)
          commit_exists?(commitish)
        end

      return if success

      git_in_depth_fetch
      raise_if_we_cannot_find_the_commit(commitish) if commit_not_exists?(commitish)
    end

    private

    def git_in_depth_fetch
      exec("fetch --depth 1000000")
    end

    def git_fetch_branch_to_depth(branch, depth)
      exec("fetch --depth=#{depth} --prune origin +refs/heads/#{branch}:refs/remotes/origin/#{branch}")
    end

    def default_env
      { "LANG" => "en_US.UTF-8" }
    end

    def raise_if_we_cannot_find_the_commit(commitish)
      raise "Commit #{commitish[0..7]} doesn't exist. Are you running `danger local/pr` against the correct repository? Also this usually happens when you rebase/reset and force-pushed."
    end

    def commit_exists?(sha1)
      !commit_not_exists?(sha1)
    end

    def commit_not_exists?(sha1)
      exec("rev-parse --quiet --verify #{sha1}^{commit}").empty?
    end

    def find_merge_base(repo, from, to)
      possible_merge_base = possible_merge_base(repo, from, to)
      return possible_merge_base if possible_merge_base

      possible_merge_base = find_merge_base_with_incremental_fetch(repo, from, to)
      return possible_merge_base if possible_merge_base

      git_in_depth_fetch
      possible_merge_base = possible_merge_base(repo, from, to)

      raise "Cannot find a merge base between #{from} and #{to}." unless possible_merge_base

      possible_merge_base
    end

    def find_merge_base_with_incremental_fetch(repo, from, to)
      from_is_ref = commit_is_ref?(from)
      to_is_ref = commit_is_ref?(to)

      return unless from_is_ref || to_is_ref

      depth = 0
      (3..6).any? do |factor|
        depth += Math.exp(factor).to_i

        git_fetch_branch_to_depth(from, depth) if from_is_ref
        git_fetch_branch_to_depth(to, depth) if to_is_ref
        possible_merge_base(repo, from, to)
      end
    end

    def possible_merge_base(repo, from, to)
      [repo.merge_base(from, to)].find { |base| commit_exists?(base) }
    end

    def commits_in_branch_count(from, to)
      exec("rev-list #{from}..#{to} --count").to_i
    end

    def commit_is_ref?(commit)
      /[a-f0-9]{5,40}/ !~ commit
    end
  end
end

module Git
  class Base
    # Use git-merge-base https://git-scm.com/docs/git-merge-base to
    # find as good common ancestors as possible for a merge
    def merge_base(commit1, commit2, *other_commits)
      Open3.popen2("git", "merge-base", commit1, commit2, *other_commits) { |_stdin, stdout, _wait_thr| stdout.read.rstrip }
    end
  end
end
