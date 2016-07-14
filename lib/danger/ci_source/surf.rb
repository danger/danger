# http://github.com/surf-build/surf

module Danger
  module CISource
    # http://github.com/surf-build/surf
    class Surf < CI
      def self.validates?(env)
        return ["SURF_REPO", "SURF_NWO"].all? { |x| env[x] }
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["SURF_NWO"]
        if env["SURF_PR_NUM"].to_i > 0
          self.pull_request_id = env["SURF_PR_NUM"]
        end

        self.repo_url = env["SURF_REPO"]
      end
    end
  end
end
