# http://devcenter.bitrise.io/docs/available-environment-variables

module Danger
  # ### CI Setup
  #
  # Add a script step to your workflow:
  # ``` yml
  # - script@1.1.2:
  #     inputs:
  #    - content: |-
  #        bundle install
  #        bundle exec danger
  # ```
  # ### Token Setup
  #
  # Add the `DANGER_GITHUB_API_TOKEN` to your workflow's Secret Env Vars
  #
  class Bitrise < CI
    def self.validates_as_ci?(env)
      env.key? "BITRISE_BUILD_URL"
    end

    def self.validates_as_pr?(env)
      return true if env["BITRISE_PULL_REQUEST"] && !env["BITRISE_PULL_REQUEST"].empty?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["BITRISE_BUILD_SLUG"]
      self.pull_request_id = env["BITRISE_PULL_REQUEST"]
      self.repo_url = env["GIT_REPOSITORY_URL"]
    end
  end
end
