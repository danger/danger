# https://buildkite.com/docs/agent/osx
# https://buildkite.com/docs/guides/environment-variables
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # With BuildKite you run the server yourself, so you will want to run  it as a part of your build process.
  # It is common to have build steps, so we would recommend adding this to your scrip:
  #
  #  ``` shell
  #   echo "--- Running Danger"
  #   bundle exec danger
  #  ```
  #
  # ### Token Setup
  #
  # #### GitHub
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.
  #
  # #### GitLab
  #
  # As this is self-hosted, you will need to add the `DANGER_GITLAB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITLAB_API_TOKEN="123" bundle exec danger`.
  #
  class Buildkite < CI
    def self.validates_as_ci?(env)
      env.key? "BUILDKITE"
    end

    def self.validates_as_pr?(env)
      exists = ["BUILDKITE_PULL_REQUEST_REPO", "BUILDKITE_PULL_REQUEST"].all? { |x| env[x] }
      exists && !env["BUILDKITE_PULL_REQUEST_REPO"].empty?
    end

    def initialize(env)
      self.repo_url = env["BUILDKITE_REPO"]
      self.pull_request_id = env["BUILDKITE_PULL_REQUEST"]

      repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/]+?)(\.git$|$)})
      self.repo_slug = repo_matches[2] unless repo_matches.nil?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::GitLab]
    end
  end
end
