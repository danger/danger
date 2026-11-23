# frozen_string_literal: true

require "git"
require "danger/request_sources/local_only"

module Danger
  # ### CI Setup
  #
  # For setting up LocalOnlyGitRepo there is not much needed. Either `--base` and `--head` need to be specified or
  # origin/master (or origin/main) is expected for base and HEAD for head
  #
  class LocalOnlyGitRepo < CI
    attr_accessor :base_commit, :head_commit

    HEAD_VAR = "DANGER_LOCAL_HEAD"
    BASE_VAR = "DANGER_LOCAL_BASE"

    # The remote-tracking branch to diff against, in order of preference. `origin/master` is what
    # Danger has always used, but repositories created since Git 2.28 typically use `origin/main`.
    DEFAULT_BASE_BRANCHES = %w(origin/master origin/main).freeze

    def self.validates_as_ci?(env)
      env.key? "DANGER_USE_LOCAL_ONLY_GIT"
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
      @supported_request_sources ||= [Danger::RequestSources::LocalOnly]
    end

    def initialize(env = {})
      # expects --base/--head specified OR origin/master (or origin/main) to be base and HEAD head
      self.base_commit = env[BASE_VAR] || default_base_commit
      self.head_commit = env[HEAD_VAR] || run_git("rev-parse --abbrev-ref HEAD")
    end

    private

    # @return [String] the remote-tracking branch to use as the base of the local diff. `origin/master`
    #   is preferred for backwards compatibility, but repositories created with Git's newer default
    #   branch name are based on `origin/main` instead. When neither exists, `origin/master` is kept so
    #   that setup_danger_branches reports it as the missing commit.
    def default_base_commit
      DEFAULT_BASE_BRANCHES.find { |branch| commit_exists?(branch) } || DEFAULT_BASE_BRANCHES.first
    end

    def commit_exists?(commitish)
      !run_git("rev-parse --quiet --verify #{commitish}").empty?
    end
  end
end
