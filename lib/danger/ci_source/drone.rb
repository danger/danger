# http://readme.drone.io/usage/variables/

module Danger
  # ### CI Setup
  #
  # With Drone you run the docker images yourself, so you will want to add `bundle exec danger` at the end of
  # your `.drone.yml`.
  #
  #  ``` shell
  #   build:
  #     image: golang
  #       commands:
  #         - ...
  #         - bundle exec danger
  #  ```
  #
  # ### Token Setup
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.
  #
  class Drone < CI
    def self.validates_as_ci?(env)
      env.key? "DRONE_REPO"
    end

    def self.validates_as_pr?(env)
      env["DRONE_PULL_REQUEST"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::GitLab]
    end

    def initialize(env)
      self.repo_slug = env["DRONE_REPO"]
      self.pull_request_id = env["DRONE_PULL_REQUEST"]
      self.repo_url = GitRepo.new.origins # Drone doesn't provide a repo url env variable :/
    end
  end
end
