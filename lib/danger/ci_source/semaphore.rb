# https://docs.semaphoreci.com/article/12-environment-variables
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
      one = ["SEMAPHORE_REPO_SLUG", "PULL_REQUEST_NUMBER"].all? { |x| env[x] && !env[x].empty? }
      two = ["SEMAPHORE_GIT_REPO_SLUG", "SEMAPHORE_GIT_PR_NUMBER"].all? { |x| env[x] && !env[x].empty? }

      one || two
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["SEMAPHORE_GIT_REPO_SLUG"] || env["SEMAPHORE_REPO_SLUG"]
      self.pull_request_id = env["SEMAPHORE_GIT_PR_NUMBER"] || env["PULL_REQUEST_NUMBER"]
      self.repo_url = env["SEMAPHORE_GIT_URL"] || GitRepo.new.origins
    end
  end
end
