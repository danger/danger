# http://devcenter.bitrise.io/docs/available-environment-variables
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # Add a script step to your workflow:
  #
  # ```yml
  # - script@1.1.2:
  #     inputs:
  #    - content: |-
  #        bundle install
  #        bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # Add the `DANGER_GITHUB_API_TOKEN` to your workflow's [Secret App Env Vars](https://blog.bitrise.io/anyone-even-prs-can-have-secrets).
  #
  class Bitrise < CI
    def self.validates_as_ci?(env)
      env.key? "BITRISE_IO"
    end

    def self.validates_as_pr?(env)
      return !env["BITRISE_PULL_REQUEST"].to_s.empty?
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud
      ]
    end

    def initialize(env)
      self.pull_request_id = env["BITRISE_PULL_REQUEST"]
      self.repo_url = env["GIT_REPOSITORY_URL"]

      repo_matches = self.repo_url.match(%r{([\/:])(([^\/]+\/){1,2}[^\/]+?)(\.git$|$)})
      self.repo_slug = repo_matches[2] unless repo_matches.nil?
    end
  end
end
