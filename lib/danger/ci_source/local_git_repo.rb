# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"
require "danger/ci_source/support/remote_finder"
require "danger/ci_source/support/pull_request_finder"
require "danger/ci_source/support/commits"
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
      puts "danger local / pr requires a repository hosted on GitHub.com or GitHub Enterprise.".freeze
    end

    def initialize(env = {})
      @env = env

      self.repo_slug = found_repo_slug ? found_repo_slug : print_repo_slug_warning
      self.pull_request_id = found_pull_request.pull_request_id

      if sha
        self.base_commit = commits.base
        self.head_commit = commits.head
      else
        self.base_commit = found_pull_request.base
        self.head_commit = found_pull_request.head
      end
    end

    private

    attr_reader :env

    def found_repo_slug
      @_found_repo_slug ||= begin
        RemoteFinder.new(
          env["DANGER_GITHUB_HOST"] || "github.com".freeze,
          run_git("remote show origin -n".freeze)
        ).call
      end
    end

    def found_pull_request
      @_found_pull_request ||= begin
        PullRequestFinder.new(
          env.fetch("LOCAL_GIT_PR_ID") { "".freeze },
          run_git("log --oneline -1000000".freeze),
          repo_slug,
          env.fetch("CHECK_OPEN_PR") { "false".freeze }
        ).call
      end
    end

    def sha
      @_sha ||= found_pull_request.sha
    end

    def commits
      @_commits ||= Commits.new(run_git("rev-list --parents -n 1 #{sha}"))
    end
  end
end
