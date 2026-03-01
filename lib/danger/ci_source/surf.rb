# http://github.com/surf-build/surf
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # You want to add `bundle exec danger` to your `build.sh` file to run  Danger at the
  # end of your build.
  #
  # ### Token Setup
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.
  #
  class Surf < CI
    def self.validates_as_ci?(env)
      return ["SURF_REPO", "SURF_NWO"].all? { |x| env[x] && !env[x].empty? }
    end

    def self.validates_as_pr?(env)
      validates_as_ci?(env)
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
