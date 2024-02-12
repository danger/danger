# https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables
require "uri"
require "danger/request_sources/github/github"
require "danger/request_sources/vsts"

module Danger
  # ### CI Setup
  #
  # Add a script step:
  #
  # ```shell
  #   #!/usr/bin/env bash
  #   bundle install
  #   bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # #### GitHub
  #
  # You need to add the `DANGER_GITHUB_API_TOKEN` environment variable, to do this, go to your build definition's variables tab.
  #
  # #### Azure Git
  #
  # You need to add the `DANGER_VSTS_API_TOKEN` and `DANGER_VSTS_HOST` environment variable, to do this,
  # go to your build definition's variables tab. The `DANGER_VSTS_API_TOKEN` is your vsts personal access token.
  # Instructions for creating a personal access token can be found [here](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/use-personal-access-tokens-to-authenticate).
  # For the `DANGER_VSTS_HOST` variable the suggested value is `$(System.TeamFoundationCollectionUri)$(System.TeamProject)`
  # which will automatically get your vsts domain and your project name needed for the vsts api.
  #
  class AzurePipelines < CI
    def self.validates_as_ci?(env)
      has_all_variables = ["AGENT_ID", "BUILD_SOURCEBRANCH", "BUILD_REPOSITORY_URI", "BUILD_REASON", "BUILD_REPOSITORY_NAME"].all? { |x| env[x] && !env[x].empty? }

      # AGENT_ID is being used by AppCenter as well, so checking here to make sure AppCenter CI doesn't get a false positive for AzurePipelines
      # Anyone working with AzurePipelines could provide a better/truly unique env key to avoid checking for AppCenter
      !Danger::Appcenter.validates_as_ci?(env) &&
        has_all_variables
    end

    def self.validates_as_pr?(env)
      return env["BUILD_REASON"] == "PullRequest"
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud,
        Danger::RequestSources::VSTS
      ]
    end

    def initialize(env)
      self.pull_request_id = env["SYSTEM_PULLREQUEST_PULLREQUESTNUMBER"] || env["SYSTEM_PULLREQUEST_PULLREQUESTID"]
      self.repo_url = env["BUILD_REPOSITORY_URI"]
      self.repo_slug = env["BUILD_REPOSITORY_NAME"]
    end
  end
end
