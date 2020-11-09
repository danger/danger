# https://docs.microsoft.com/en-us/appcenter/build/custom/variables/
require "uri"
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # Add a script step to your appcenter-post-build.sh:
  #
  # ```shell
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

    def self.owner_for_github(env)
      URI.parse(env["BUILD_REPOSITORY_URI"]).path.split("/")[1]
    end

    def self.repo_identifier_for_github(env)
      repo_name = env["BUILD_REPOSITORY_NAME"]
      owner = owner_for_github(env)
      "#{owner}/#{repo_name}"
    end

    # Hopefully it's a temporary workaround (same as in Codeship integration) because App Center
    # doesn't expose PR's ID. There's a future request https://github.com/Microsoft/appcenter/issues/79
    def self.pr_from_env(env)
      Danger::RequestSources::GitHub.new(nil, env).get_pr_from_branch(repo_identifier_for_github(env), env["BUILD_SOURCEBRANCHNAME"], owner_for_github(env))
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.pull_request_id = self.class.pr_from_env(env)
      self.repo_url = env["BUILD_REPOSITORY_URI"]
      self.repo_slug = self.class.repo_identifier_for_github(env)
    end
  end
end
