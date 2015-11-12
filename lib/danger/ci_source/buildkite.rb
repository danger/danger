# https://buildkite.com/docs/agent/osx
# https://buildkite.com/docs/guides/environment-variables

module Danger
  module CISource
    class Buildkite < CI
      def self.validates?(env)
        return !env["BUILDKITE"].nil?
      end

      def initialize(env)
        repo = env["BUILDKITE_REPO"]
        if !repo.nil?
          repo_matches = repo.match(/([\/:])([^\/]+\/[^\/.]+)(?:.git)?$/)
          self.repo_slug = repo_matches[2] if !repo_matches.nil?
        end

        self.pull_request_id = env["BUILDKITE_PULL_REQUEST"]
      end
    end
  end
end
