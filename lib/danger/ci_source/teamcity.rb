module Danger
  module CISource
    # https://www.jetbrains.com/teamcity/
    class TeamCity < CI
      def self.validates?(env)
        env.key? "TEAMCITY_VERSION"
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        # NB: Unfortunately TeamCity doesn't provide these variables
        # automatically so you have to add these variables manually to your
        # project or build configuration
        self.repo_slug       = env["GITHUB_REPO_SLUG"]
        self.pull_request_id = env["GITHUB_PULL_REQUEST_ID"].to_i
        self.repo_url        = env["GITHUB_REPO_URL"]
      end
    end
  end
end
