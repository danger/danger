require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # You can use `danger/danger` Action in your .github/main.workflow.
  #
  #  ```
  # action "Danger" {
  #    uses = "danger/danger"
  # }
  #  ```
  #
  # ### Token Setup
  #
  # Set DANGER_GITHUB_API_TOKEN to secrets, or you can also use GITHUB_TOKEN.
  #
  # ```
  # action "Danger" {
  #    uses = "danger/danger"
  #    secrets = ["GITHUB_TOKEN"]
  # }
  # ```
  #
  class GitLabCIGitHubPR < CI
    def self.validates_as_ci?(env)
      env.key? "GITLAB_PB"
    end

    def self.validates_as_pr?(env)
      true
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env['DANGER_REPO_SLUG']
      self.pull_request_id = env['PULL_REQUEST_ID']
      self.repo_url = env['DANGER_REPO_URL']

      # if environment variable DANGER_GITHUB_API_TOKEN is not set, use env GITHUB_TOKEN
      if (env.key? "GITLAB_PB") && (!env.key? 'DANGER_GITHUB_API_TOKEN')
        env['DANGER_GITHUB_API_TOKEN'] = env['GITHUB_CHANGELOG_TOKEN']
      end
    end
  end
end
