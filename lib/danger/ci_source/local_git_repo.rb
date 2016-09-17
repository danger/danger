# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"
require "danger/ci_source/support/remote_finder"
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

    def print_repo_slug_warning
      puts "Danger local requires a repository hosted on GitHub.com or GitHub Enterprise.".freeze
    end

    def parents(sha)
      @parents ||= run_git("rev-list --parents -n 1 #{sha}").strip.split(" ".freeze)
    end

    def initialize(env = {})
      repo_slug = RemoteFinder.new(
        github_host: env["DANGER_GITHUB_HOST"] || "github.com".freeze,
        remote_logs: run_git("remote show origin -n")
      ).call

      pull_request_id, sha = MergedPullRequestFinder.new(
        specific_pull_request_id: env["LOCAL_GIT_PR_ID"],
        git_logs: run_git("log --oneline -50".freeze)
      ).call

      self.repo_slug = repo_slug ? repo_slug : print_repo_slug_warning
      self.pull_request_id = pull_request_id
      self.base_commit = parents(sha)[0]
      self.head_commit = parents(sha)[1]
    end
  end
end
