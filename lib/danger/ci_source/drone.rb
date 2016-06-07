# http://readme.drone.io/usage/variables/

module Danger
  module CISource
    class Drone < CI
      def self.validates?(env)
        return !env["DRONE"].nil?
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["DRONE_REPO"]
        if env["DRONE_PULL_REQUEST"].to_i > 0
          self.pull_request_id = env["DRONE_PULL_REQUEST"]
        end
      end
    end
  end
end
