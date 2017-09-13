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
      return false unless env["CI_BRANCH"] && !env["CI_BRANCH"].empty?

      !pr_from_env(env).nil?
    end

    def self.owner_for_github(env)
      env["CI_REPO_NAME"].split("/").first
    end

    # this is fairly hacky, see https://github.com/danger/danger/pull/892#issuecomment-329030616 for why
    def self.pr_from_env(env)
      Danger::RequestSources::GitHub.new(nil, env).get_pr_from_branch(env["CI_REPO_NAME"], env["CI_BRANCH"], owner_for_github(env))
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["CI_REPO_NAME"]
      self.pull_request_id = self.class.pr_from_env(env)
      self.repo_url = GitRepo.new.origins
    end
  end
end
