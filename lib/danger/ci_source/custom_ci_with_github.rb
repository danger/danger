# frozen_string_literal: true

require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # Custom CI with GitHub
  #
  # This CI source is for custom, most likely internal, CI systems that are use GitHub as source control.
  # An example could be argo-workflows or tekton hosted in your own Kubernetes cluster.
  #
  # The following environment variables are required:
  # - `CUSTOM_CI_WITH_GITHUB` - Set to any value to indicate that this is a custom CI with GitHub
  #
  # ### Token Setup
  #
  # #### GitHub
  # As you own the setup, it's up to you to add the environment variable for the `DANGER_GITHUB_API_TOKEN`.
  #
  class CustomCIWithGithub < CI
    def self.validates_as_ci?(env)
      env.key? "CUSTOM_CI_WITH_GITHUB"
    end

    def self.validates_as_pr?(env)
      value = env["GITHUB_EVENT_NAME"]
      ["pull_request", "pull_request_target"].include?(value)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      super

      self.repo_slug = env["GITHUB_REPOSITORY"]
      pull_request_event = JSON.parse(File.read(env["GITHUB_EVENT_PATH"]))
      self.pull_request_id = pull_request_event["number"]
      self.repo_url = pull_request_event["repository"]["clone_url"]

      # if environment variable DANGER_GITHUB_API_TOKEN is not set, use env GITHUB_TOKEN
      if (env.key? "CUSTOM_CI_WITH_GITHUB") && (!env.key? "DANGER_GITHUB_API_TOKEN")
        env["DANGER_GITHUB_API_TOKEN"] = env["GITHUB_TOKEN"]
      end
    end
  end
end
