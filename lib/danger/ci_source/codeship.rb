# https://semaphoreci.com/docs/available-environment-variables.html
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # In Codeship, go to your "Project Settings", then add `bundle exec danger` as a test step inside
  # one of your pipelines.
  #
  # ### Token Setup
  #
  # Add your `DANGER_GITHUB_API_TOKEN` to "Environment" section in "Project Settings".
  #
  class Codeship < CI
    def self.validates_as_ci?(env)
      env["CI_NAME"] == "codeship"
    end

    def self.validates_as_pr?(env)
      env["CI_BRANCH"] && !env["CI_BRANCH"].empty? && env["CI_BRANCH"] == "master"
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["CI_REPO_NAME"]
      owner = env["CI_REPO_NAME"].split("/").first
      self.pull_request_id = Danger::RequestSources::GitHub.new(self, env).get_pr_from_branch(env["CI_REPO_NAME"], env["CI_BRANCH"], owner)
      self.repo_url = GitRepo.new.origins
    end
  end
end
