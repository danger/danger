# For more info see: https://github.com/schacon/ruby-git

require 'grit'
require 'uri'

module Danger
  module CISource
    class LocalGitRepo < CI
      attr_accessor :base_commit, :head_commit

      def self.validates?(env)
        return !env["DANGER_USE_LOCAL_GIT"].nil?
      end

      def git
        @git ||= Grit::Git.new(".")
      end

      def run_git(command)
        binary = Grit::Git.git_binary
        git.sh "#{binary} #{command}"
      end

      def initialize(*)
        # get the remote URL
        remote = run_git "remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-"
        if remote
          remote_url_matches = remote.first.chomp.match(%r{github\.com(:|/)(?<repo_slug>.+/.+?)(?:\.git)?$})
          if !remote_url_matches.nil? and remote_url_matches["repo_slug"]
            self.repo_slug = remote_url_matches["repo_slug"]
          else
            puts "Danger local requires a repository hosted on github."
          end
        end

        # get the most recent PR merge
        logs = run_git "log --since='2 weeks ago' --merges --oneline | grep \"Merge pull request\" | head -n 1"
        pr_merge = logs[0].strip
        if pr_merge
          self.pull_request_id = pr_merge.match("#[0-9]*")[0].delete("#")
          sha = pr_merge.split(" ")[0]
          parents = run_git "rev-list --parents -n 1 #{sha}"
          self.base_commit = parents[0].strip.split(" ")[0]
          self.head_commit = parents[0].strip.split(" ")[1]
        end
      end
    end
  end
end
