require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  # You need to edit your `.cirrus.yml` to include `bundler exec danger`.
  #
  # Adding this to your `.cirrus.yml` allows Danger to fail your build, both on the Cirrus CI website and within your Pull Request.
  # With that set up, you can edit your task to add `bundler exec danger` in any script instruction.
  class Cirrus < CI
    def self.validates_as_ci?(env)
      env.key? "CIRRUS_CI"
    end

    def self.validates_as_pr?(env)
      exists = ["CIRRUS_PR", "CIRRUS_REPO_FULL_NAME"].all? { |x| env[x] && !env[x].empty? }
      exists && env["CIRRUS_PR"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["CIRRUS_REPO_FULL_NAME"]
      if env["CIRRUS_PR"].to_i > 0
        self.pull_request_id = env["CIRRUS_PR"]
      end
      self.repo_url = env["CIRRUS_GIT_CLONE_URL"]
    end
  end
end
