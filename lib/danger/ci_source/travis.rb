# http://docs.travis-ci.com/user/osx-ci-environment/
# http://docs.travis-ci.com/user/environment-variables/

module Danger
  module CISource
    class Travis < CI
      def self.validates?(env)
        return !env["HAS_JOSH_K_SEAL_OF_APPROVAL"].nil?
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["TRAVIS_REPO_SLUG"]
        # from https://docs.travis-ci.com/user/pull-requests, as otherwise it's "false"
        if env["TRAVIS_PULL_REQUEST"].to_i > 0
          self.pull_request_id = env["TRAVIS_PULL_REQUEST"]
        end
      end
    end
  end
end
