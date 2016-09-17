# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"
require "danger/ci_source/support/merged_pull_request_finder"

module Danger
  # ignore
  class LocalGitRepo < CI
    attr_accessor :base_commit, :head_commit

    def self.validates_as_ci?(env)
      env.key? "DANGER_USE_LOCAL_GIT"
    end

    def self.validates_as_pr?(_env)
      false
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
      remote = run_git("remote show origin -n").lines.grep(/Fetch URL/)[0].split(": ", 2)[1]
      if remote
        remote_url_matches = remote.match(%r{#{Regexp.escape github_host}(:|/)(?<repo_slug>.+/.+?)(?:\.git)?$})
        if !remote_url_matches.nil? and remote_url_matches["repo_slug"]
          self.repo_slug = remote_url_matches["repo_slug"]
        else
          puts "Danger local requires a repository hosted on GitHub.com or GitHub Enterprise."
        end
      end

      pull_request_id, sha = MergedPullRequestFinder.new(
        specific_pull_request_id: env["LOCAL_GIT_PR_ID"], git: git
      ).call

      self.pull_request_id = pull_request_id
      parents = run_git("rev-list --parents -n 1 #{sha}").strip.split(" ".freeze)
      self.base_commit = parents[0]
      self.head_commit = parents[1]
    end
  end
end
