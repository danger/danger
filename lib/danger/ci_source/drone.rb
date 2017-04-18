# http://readme.drone.io/usage/variables/
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # With Drone you run the docker images yourself, so you will want to add `bundle exec danger` at the end of
  # your `.drone.yml`.
  #
  #  ``` shell
  #   build:
  #     image: golang
  #     commands:
  #       - ...
  #       - bundle exec danger
  #  ```
  #
  # ### Token Setup
  #
  # As this is self-hosted, you will need to expose the `DANGER_GITHUB_API_TOKEN` as a secret to your
  # builds:
  #
  # Drone secrets: http://readme.drone.io/usage/secret-guide/
  # NOTE: This is a new syntax in DroneCI 0.6+
  #
  # ```
  #   build:
  #     image: golang
  #     secrets:
  #       - DANGER_GITHUB_API_TOKEN
  #     commands:
  #       - ...
  #       - bundle exec danger
  # ```
  class Drone < CI
    def self.validates_as_ci?(env)
      env.key? "DRONE_REPO_OWNER" and env.key? "DRONE_REPO_NAME"
    end

    def self.validates_as_pr?(env)
      env["DRONE_PULL_REQUEST"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::GitLab]
    end

    def initialize(env)
      self.repo_slug = "#{env['DRONE_REPO_OWNER']}/#{env['DRONE_REPO_NAME']}"
      self.pull_request_id = env["DRONE_PULL_REQUEST"]
      self.repo_url = env["DRONE_REPO_LINK"]
    end
  end
end
