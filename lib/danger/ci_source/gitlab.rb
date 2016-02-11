# https://circleci.com/docs/environment-variables
require 'uri'

module Danger
  module CISource
    class GitlabCI < CI
      def self.validates?(env)
        return !env["GITLAB_CI"].nil? && !env["GITLAB_CI_PULL"].nil?
      end

      def initialize(env)
          # The first one is an extra slash, ignore it
          self.repo_slug = "FXF/FXF-IOS"
          self.pull_request_id = env["GITLAB_CI_PULL"];
      end
    end
  end
end
