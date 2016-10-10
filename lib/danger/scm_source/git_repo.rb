# For more info see: https://github.com/schacon/ruby-git

require "git"

module Danger
  class GitRepo
    attr_accessor :diff, :log, :folder

    def diff_for_folder(folder, from: "master", to: "HEAD")
      self.folder = folder
      repo = Git.open self.folder

      base_sha = exec("rev-parse --verify --quiet #{from}")
      head_sha = exec("rev-parse --verify --quiet #{to}")

      ensure_commitish_exists!(base_sha)
      ensure_commitish_exists!(head_sha)

      merge_base = best_merge_base(repo, base_sha, head_sha)

      ensure_commitish_exists!(merge_base)

      self.diff = repo.diff(merge_base, to)
      self.log = repo.log.between(from, to)
    rescue Exception => exception
      puts "="*100
        puts "*"*100
        p repo
        p from
        p to
        puts "*"*100
      raise exception
      puts "="*100
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
      exec "rev-parse HEAD"
    end

    def origins
      exec("remote show origin -n").lines.grep(/Fetch URL/)[0].split(": ", 2)[1].chomp
    end

    def ensure_commitish_exists!(commitish)
      exec("fetch --all") if commit_not_exists?(commitish)

      if commit_not_exists?(commitish)
        raise_if_we_cannot_find_the_commit(commitish)
      end
    end

    private

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

    def best_merge_base(repo, from, to)
      possible_merge_base = [repo.merge_base(from, to)].find { |base| commit_exists?(base) }

      raise "Cannot find a merge base between #{from} and #{to}." unless possible_merge_base

      possible_merge_base
    end
  end
end

module Git
  class Base
    # Use git-merge-base https://git-scm.com/docs/git-merge-base to
    # find as good common ancestors as possible for a merge
    def merge_base(commit1, commit2, *other_commits)
      Open3.popen2("git", "merge-base", "--all", commit1, commit2, *other_commits) { |_stdin, stdout, _wait_thr| stdout.read.rstrip }
    end
  end
end
