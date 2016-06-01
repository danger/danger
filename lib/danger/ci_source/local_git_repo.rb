# For more info see: https://github.com/schacon/ruby-git

require 'git'
require 'uri'

module Danger
  module CISource
    class LocalGitRepo < CI
      attr_accessor :base_commit, :head_commit

      def self.validates?(env)
        return !env["DANGER_USE_LOCAL_GIT"].nil?
      end

      def git
        @git ||= GitRepo.new
      end

      def run_git(command)
        git.exec command
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env = {})
        github_host = env["DANGER_GITHUB_HOST"] || "github.com"

        # get the remote URL
        remote = run_git "remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-"
        if remote
          remote_url_matches = remote.match(%r{#{Regexp.escape github_host}(:|/)(?<repo_slug>.+/.+?)(?:\.git)?$})
          if !remote_url_matches.nil? and remote_url_matches["repo_slug"]
            self.repo_slug = remote_url_matches["repo_slug"]
          else
            puts "Danger local requires a repository hosted on GitHub.com or GitHub Enterprise."
          end
        end

        specific_pr = env["LOCAL_GIT_PR_ID"]
        pr_ref = specific_pr ? "##{specific_pr}" : ''
        pr_command = "log --merges --oneline | grep \"Merge pull request #{pr_ref}\" | head -n 1"

        # get the most recent PR merge
        pr_merge = run_git pr_command.strip

        if pr_merge.to_s.empty?
          if specific_pr
            raise "Could not find the pull request (#{specific_pr}) inside the git history for this repo."
          else
            raise "No recent pull requests found for this repo, danger requires at least one PR for the local mode."
          end
        end

        self.pull_request_id = pr_merge.match("#([0-9]+)")[1]
        sha = pr_merge.split(" ")[0]
        parents = run_git("rev-list --parents -n 1 #{sha}").strip.split(" ")
        self.base_commit = parents[0]
        self.head_commit = parents[1]
      end
    end
  end
end
