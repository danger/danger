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
      merge_base = repo.merge_base(from, to)

      ensure_commitish_exists!(merge_base)
      self.diff = repo.diff(merge_base.to_s, to)
      self.log = repo.log.between(from, to)
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

    private

    def default_env
      { "LANG" => "en_US.UTF-8" }
    end

    def ensure_commitish_exists!(commitish)
      exec "fetch" if exec("--no-pager show #{commitish}").empty?
    end
  end
end

# For full context see:
# https://github.com/danger/danger/issues/160
# and https://github.com/danger/danger/issues/316
#
# for which the fix comes from an unmerged PR from 2012
# https://github.com/schacon/ruby-git/pull/43

module Git
  class Base
    def merge_base(commit1, commit2, *other_commits)
      Git::Object.new self, self.lib.merge_base(commit1, commit2, *other_commits)
    end
  end

  class Lib
    def merge_base(commit1, commit2, *other_commits)
      arr_opts = []
      arr_opts << commit1
      arr_opts << commit2
      arr_opts += other_commits
      command("merge-base", arr_opts)
    end
  end
end
