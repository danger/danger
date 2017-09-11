# https://semaphoreci.com/docs/available-environment-variables.html
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # For Semaphore you will want to go to the settings page of the project. Inside "Build Settings"
  # you should add `bundle exec danger` to the Setup thread. Note that Semaphore only provides
  # the build environment variables necessary for Danger on PRs across forks.
  #
  # ### Token Setup
  #
  # You can add your `DANGER_GITHUB_API_TOKEN` inside the "Environment Variables" section in the settings.
  #
  class Semaphore < CI
    def self.validates_as_ci?(env)
      env.key? "SEMAPHORE"
    end

    def self.validates_as_pr?(env)
      ["SEMAPHORE_REPO_SLUG", "PULL_REQUEST_NUMBER"].all? { |x| env[x] && !env[x].empty? }
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["SEMAPHORE_REPO_SLUG"]
      self.pull_request_id = env["PULL_REQUEST_NUMBER"]
      self.repo_url = GitRepo.new.origins # Semaphore doesn't provide a repo url env variable :/
    end
  end
end
