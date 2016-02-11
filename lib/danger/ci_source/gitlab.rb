# https://circleci.com/docs/environment-variables
require 'uri'

module Danger
  module CISource
    class GitlabCI < CI
      def self.validates?(env)
        return !env["GITLAB_PROJECT_ID"].nil? && !env["GITLAB_MR_ID"].nil?
      end

      def initialize(env)
          # The first one is an extra slash, ignore it
          self.repo_slug = env["GITLAB_PROJECT_ID"];
          self.pull_request_id = env["GITLAB_MR_ID"];
      end
    end
  end
end
