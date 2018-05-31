# http://screwdriver.cd
# https://docs.screwdriver.cd/user-guide/environment-variables
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your screwdriver.yaml:
  # ``` yml
  # jobs:
  #   danger:
  #     requires: [~pr, ~commit]
  #     steps:
  #       - setup: bundle install --path vendor
  #       - danger: bundle exec danger
  #     secrets:
  #       - DANGER_GITHUB_API_TOKEN
  # ```
  #
  # ### Token Setup
  #
  # Add the `DANGER_GITHUB_API_TOKEN` to your pipeline env as a
  # [build secret](https://docs.screwdriver.cd/user-guide/configuration/secrets)
  #
  class Screwdriver < CI
    def self.validates_as_ci?(env)
      env.key? "SCREWDRIVER"
    end

    def self.validates_as_pr?(env)
      exists = ["SD_PULL_REQUEST", "SCM_URL"].all? { |x| env[x] && !env[x].empty? }
      exists && env["SD_PULL_REQUEST"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["SCM_URL"].split(":").last.gsub(".git", "").split("#", 2).first
      self.repo_url = env["SCM_URL"].split("#", 2).first
      if env["SD_PULL_REQUEST"].to_i > 0
        self.pull_request_id = env["SD_PULL_REQUEST"]
      end
    end
  end
end
