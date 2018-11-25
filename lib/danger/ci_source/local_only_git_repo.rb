require "git"
require "danger/request_sources/local_only"

module Danger
  # ### CI Setup
  #
  # For setting up LocalOnlyGitRepo there is not much needed. Either `--base` and `--head` need to be specified or
  # origin/master is expected for base and HEAD for head
  #
  class LocalOnlyGitRepo < CI
    attr_accessor :base_commit, :head_commit
    HEAD_VAR = "DANGER_LOCAL_HEAD".freeze
    BASE_VAR = "DANGER_LOCAL_BASE".freeze

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
      @env = env

      # expects --base/--head specified OR origin/master to be base and HEAD head
      self.base_commit = env[BASE_VAR] || run_git("rev-parse --abbrev-ref origin/master")
      self.head_commit = env[HEAD_VAR] || run_git("rev-parse --abbrev-ref HEAD")
    end

    private

    attr_reader :env
  end
end
