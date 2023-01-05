# https://semaphoreci.com/docs/available-environment-variables.html
require "danger/request_sources/github/github"

module Danger
  #  ### CI Setup
  #
  #  To set up Danger on Codefresh, create a freestyle step in your Codefresh yaml configuration:
  #
  #  ```yml
  #  Danger:
  #    title: Run Danger
  #    image: alpine/bundle
  #    working_directory: ${{main_clone}}
  #    commands:
  #      - bundle install --deployment
  #      - bundle exec danger --verbose
  #  ```
  #
  #  Don't forget to add the `DANGER_GITHUB_API_TOKEN` variable to your pipeline settings so that Danger can properly post comments to your pull request.
  #
  class Codefresh < CI
    def self.validates_as_ci?(env)
      env.key?("CF_BUILD_ID") && env.key?("CF_BUILD_URL")
    end

    def self.validates_as_pr?(env)
      return !env["CF_PULL_REQUEST_NUMBER"].to_s.empty?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def self.slug_from(env)
      return "" if env["CF_REPO_OWNER"].to_s.empty?
      return "" if env["CF_REPO_NAME"].to_s.empty?

      "#{env['CF_REPO_OWNER']}/#{env['CF_REPO_NAME']}".downcase!
    end

    def initialize(env)
      self.repo_url = env["CF_COMMIT_URL"].to_s.gsub(%r{/commit.+$}, "")
      self.repo_slug = self.class.slug_from(env)
      self.pull_request_id = env["CF_PULL_REQUEST_NUMBER"]
    end
  end
end
