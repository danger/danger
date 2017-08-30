require "danger/request_sources/vsts"

module Danger
  # ### CI Setup
  #
  # You need to go to your project's build definiton. Then add a "Command Line" Task with the "Tool" field set to  "bundle"
  # and the "Arguments" field set to "exec danger".
  #
  # ### Token Setup
  #
  # #### VSTS
  # 
  # You need to add the `DANGER_VSTS_API_TOKEN` and `DANGER_VSTS_HOST` environment variable, to do this,
  # go to your build definition's variables tab. The `DANGER_VSTS_API_TOKEN` is your vsts personal access token.
  # Instructions for creating a personal access token can be found [here](https://www.visualstudio.com/en-us/docs/setup-admin/team-services/use-personal-access-tokens-to-authenticate).
  # For the `DANGER_VSTS_HOST` variable the suggested value is `$(System.TeamFoundationCollectionUri)$(System.TeamProject)`
  # which will automatically get your vsts domain and your project name needed for the vsts api.
  #
  # Make sure `DANGER_VSTS_API_TOKEN` is not secret since it won't vsts does not expose secret variables
  # when building.
  #
  class VSTS < CI
    def self.validates_as_ci?(env)
      value = env["BUILD_BUILDID"]
      return !value.nil? && !env["BUILD_BUILDID"].empty?
    end

    def self.validates_as_pr?(env)
      value = env["SYSTEM_PULLREQUEST_PULLREQUESTID"]
      return !value.nil? && !env["SYSTEM_PULLREQUEST_PULLREQUESTID"].empty?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::VSTS]
    end

    def initialize(env)
      team_project = env["SYSTEM_TEAMPROJECT"]
      repo_name = env["BUILD_REPOSITORY_URI"].split("/").last

      self.repo_slug = "#{team_project}/#{repo_name}"
      self.pull_request_id = env["SYSTEM_PULLREQUEST_PULLREQUESTID"]
      self.repo_url = env["BUILD_REPOSITORY_URI"]
    end
  end
  end
