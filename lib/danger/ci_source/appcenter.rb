# https://docs.microsoft.com/en-us/appcenter/build/custom/variables/
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # Add a script step to your appcenter-post-build.sh:
  #
  # ``` shell
  #   #!/usr/bin/env bash
  #   bundle install
  #   bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # Add the `DANGER_GITHUB_API_TOKEN` to your environment variables.
  #
  class Appcenter < CI
    def self.validates_as_ci?(env)
      env.key? "APPCENTER_BUILD_ID"
    end

    def self.validates_as_pr?(env)
      return env["BUILD_REASON"] == "PullRequest"
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
