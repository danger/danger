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
        unless repo.nil?
          repo_matches = repo.match(%r{([\/:])([^\/]+\/[^\/.]+)(?:.git)?$})
          self.repo_slug = repo_matches[2] unless repo_matches.nil?
        end

        self.pull_request_id = env["BUILDKITE_PULL_REQUEST"]
        self.head_commit = env["BUILDKITE_BRANCH"]
        self.base_commit = "master"
      end
    end
  end
end
