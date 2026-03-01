# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"

require "danger/request_sources/github/github"

require "danger/ci_source/support/find_repo_info_from_url"
require "danger/ci_source/support/find_repo_info_from_logs"
require "danger/ci_source/support/no_repo_info"
require "danger/ci_source/support/pull_request_finder"
require "danger/ci_source/support/commits"

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
      git.exec(command).encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "")
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env = {})
      @env = env

      self.repo_slug = remote_info.slug
      raise_error_for_missing_remote if remote_info.kind_of?(NoRepoInfo)

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

    def raise_error_for_missing_remote
      raise missing_remote_error_message
    end

    def missing_remote_error_message
      "danger cannot find your git remote, please set a remote. " \
      "And the repository must host on GitHub.com or GitHub Enterprise."
    end

    def remote_info
      @_remote_info ||= begin
        remote_info = begin
          if given_pull_request_url?
            FindRepoInfoFromURL.new(env["LOCAL_GIT_PR_URL"]).call
          else
            FindRepoInfoFromLogs.new(
              env["DANGER_GITHUB_HOST"] || "github.com".freeze,
              run_git("remote show origin -n".freeze)
            ).call
          end
        end

        remote_info || NoRepoInfo.new
      end
    end

    def found_pull_request
      @_found_pull_request ||= begin
        if given_pull_request_url?
          PullRequestFinder.new(
            remote_info.id,
            remote_info.slug,
            remote: true
          ).call
        else
          PullRequestFinder.new(
            env.fetch("LOCAL_GIT_PR_ID") { "".freeze },
            remote_info.slug,
            remote: false,
            git_logs: run_git("log --oneline -1000000".freeze)
          ).call
        end
      end
    end

    def given_pull_request_url?
      env["LOCAL_GIT_PR_URL"] && !env["LOCAL_GIT_PR_URL"].empty?
    end

    def sha
      @_sha ||= found_pull_request.sha
    end

    def commits
      @_commits ||= Commits.new(run_git("rev-list --parents -n 1 #{sha}"))
    end
  end
end
