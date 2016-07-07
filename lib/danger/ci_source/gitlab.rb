# https://circleci.com/docs/environment-variables
require "uri"

module Danger
  class GitlabCI < CI
    def self.validates_as_ci?(env)
      env.key? "DRONE_REPO"
    end

    def self.validates_as_pr?(env)
      env["DRONE_PULL_REQUEST"].to_i > 0
    end

    def self.validates?(env)
      return !env["GITLAB_PROJECT_ID"].nil? && !env["GITLAB_MR_ID"].nil?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitLab]
    end

    def initialize(env)
      # The first one is an extra slash, ignore it
      self.repo_slug = env["GITLAB_PROJECT_ID"]
      self.pull_request_id = env["GITLAB_MR_ID"]
    end
  end
end
