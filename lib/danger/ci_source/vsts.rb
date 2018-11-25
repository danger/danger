require "danger/request_sources/github/github"
require "danger/request_sources/vsts"

module Danger
  # ### CI Setup
  #
  # You need to go to your project's build definiton. Then add a "Command Line" Task with the "Tool" field set to  "bundle"
  # and the "Arguments" field set to "exec danger".
  #
  # ### Token Setup
  #
  # #### GitHub
  #
  # You need to add the `DANGER_GITHUB_API_TOKEN` environment variable, to do this, go to your build definition's variables tab.
  #
  # Make sure that `DANGER_GITHUB_API_TOKEN` is not set to secret since vsts does not expose secret variables while building.
  #
  # #### VSTS
  #
  # You need to add the `DANGER_VSTS_API_TOKEN` and `DANGER_VSTS_HOST` environment variable, to do this,
  # go to your build definition's variables tab. The `DANGER_VSTS_API_TOKEN` is your vsts personal access token.
  # Instructions for creating a personal access token can be found [here](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/use-personal-access-tokens-to-authenticate).
  # For the `DANGER_VSTS_HOST` variable the suggested value is `$(System.TeamFoundationCollectionUri)$(System.TeamProject)`
  # which will automatically get your vsts domain and your project name needed for the vsts api.
  #
  # Make sure that `DANGER_VSTS_API_TOKEN` is not set to secret since vsts does not expose secret variables while building.
  #
  class VSTS < CI
    class << self
      def github_slug(env)
        env["BUILD_REPOSITORY_NAME"]
      end

      def vsts_slug(env)
        project_name = env["SYSTEM_TEAMPROJECT"]
        repo_name = env["BUILD_REPOSITORY_NAME"]

        "#{project_name}/#{repo_name}"
      end
    end

    def self.validates_as_ci?(env)
      has_all_variables = ["SYSTEM_TEAMFOUNDATIONCOLLECTIONURI", "BUILD_REPOSITORY_PROVIDER"].all? { |x| env[x] && !env[x].empty? }

      is_support_source_control = ["GitHub", "TfsGit"].include?(env["BUILD_REPOSITORY_PROVIDER"])

      has_all_variables && is_support_source_control
    end

    def self.validates_as_pr?(env)
      has_all_variables = ["BUILD_SOURCEBRANCH", "BUILD_REPOSITORY_URI", "BUILD_REASON", "BUILD_REPOSITORY_NAME"].all? { |x| env[x] && !env[x].empty? }

      has_all_variables && env["BUILD_REASON"] == "PullRequest"
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::VSTS]
    end

    def initialize(env)
      case env["BUILD_REPOSITORY_PROVIDER"]
      when "GitHub"
        self.repo_slug = self.class.github_slug(env)
      when "TfsGit"
        self.repo_slug = self.class.vsts_slug(env)
      end

      repo_matches = env["BUILD_SOURCEBRANCH"].match(%r{refs\/pull\/([0-9]+)\/merge})
      self.pull_request_id = repo_matches[1] unless repo_matches.nil?
      self.repo_url = env["BUILD_REPOSITORY_URI"]
    end
  end
end
