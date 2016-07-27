# https://buildkite.com/docs/agent/osx
# https://buildkite.com/docs/guides/environment-variables

module Danger
  module CISource
    # https://buildkite.com
    class Buildkite < CI
      def self.validates?(env)
        return false unless env["BUILDKITE"]

        return true
      end

      def initialize(env)
        if env["BUILDKITE_PULL_REQUEST_REPO"] && env["BUILDKITE_PULL_REQUEST"]
          unless env["BUILDKITE_PULL_REQUEST_REPO"].empty?
            self.repo_url = env["BUILDKITE_PULL_REQUEST_REPO"]
            self.pull_request_id = env["BUILDKITE_PULL_REQUEST"]

            repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/.]+)(?:.git)?$})
            self.repo_slug = repo_matches[2] unless repo_matches.nil?
          end
        end
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end
    end
  end
end
