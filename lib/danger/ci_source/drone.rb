# http://readme.drone.io/usage/variables/

module Danger
  module CISource
    # https://drone.io
    class Drone < CI
      def self.validates?(env)
        return false unless env["DRONE"]
        return false unless env["DRONE_REPO"]
        return false unless env["DRONE_PULL_REQUEST"].to_i > 0

        return true
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["DRONE_REPO"]
        self.pull_request_id = env["DRONE_PULL_REQUEST"]
        self.repo_url = GitRepo.new.origins # Drone doesn't provide a repo url env variable :/
      end
    end
  end
end
