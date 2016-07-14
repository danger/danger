# http://docs.travis-ci.com/user/osx-ci-environment/
# http://docs.travis-ci.com/user/environment-variables/

module Danger
  module CISource
    # https://travis-ci.com
    class Travis < CI
      def self.validates?(env)
        return false unless env["HAS_JOSH_K_SEAL_OF_APPROVAL"]
        return false unless env["TRAVIS_REPO_SLUG"]
        return false unless env["TRAVIS_PULL_REQUEST"]

        return true
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["TRAVIS_REPO_SLUG"]
        if env["TRAVIS_PULL_REQUEST"].to_i > 0
          self.pull_request_id = env["TRAVIS_PULL_REQUEST"]
        end
        self.repo_url = GitRepo.new.origins # Travis doesn't provide a repo url env variable :/
      end
    end
  end
end
