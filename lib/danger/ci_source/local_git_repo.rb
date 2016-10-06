# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"
require "danger/ci_source/support/remote_finder"
require "danger/ci_source/support/pull_request_finder"
require "danger/request_sources/github"

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
        env["DANGER_GITHUB_HOST"] || "github.com".freeze,
        run_git("remote show origin -n".freeze)
      ).call

      found_pull_request = begin
        PullRequestFinder.new(
          env.fetch("LOCAL_GIT_PR_ID") { "".freeze },
          run_git("log --oneline -1000000".freeze),
          repo_slug,
          env.fetch("CHECK_OPEN_PR") { "false".freeze }
        ).call
      end

      self.repo_slug = repo_slug ? repo_slug : print_repo_slug_warning
      self.pull_request_id = found_pull_request.pull_request_id
      sha = found_pull_request.sha

      if sha
        self.base_commit = parents(sha)[0]
        self.head_commit = parents(sha)[1]
      else
        self.base_commit = found_pull_request.base
        self.head_commit = found_pull_request.head
      end
    end
  end
end
