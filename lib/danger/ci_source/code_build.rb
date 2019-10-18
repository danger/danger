# https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # In CodeBuild, make sure to correctly forward CODEBUILD_BUILD_ID, CODEBUILD_SOURCE_VERSION, CODEBUILD_SOURCE_REPO_URL and DANGER_GITHUB_API_TOKEN.
  #
  # ### Token Setup
  #
  # Add your `DANGER_GITHUB_API_TOKEN` to your project. Edit -> Environment -> Additional configuration -> Create a parameter
  #
  class CodeBuild < CI
    def self.validates_as_ci?(env)
      env.key? "CODEBUILD_BUILD_ID"
    end

    def self.validates_as_pr?(env)
      !!self.extract_pr_url(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = self.class.extract_repo_slug(env)
      self.pull_request_id = env["CODEBUILD_SOURCE_VERSION"].split("/")[1].to_i
      self.repo_url = self.class.extract_repo_url(env)
    end

    def self.extract_repo_slug(env)
      return nil unless env.key? "CODEBUILD_SOURCE_REPO_URL"

      gh_host = env["DANGER_GITHUB_HOST"] || "github.com"

      env["CODEBUILD_SOURCE_REPO_URL"].gsub(%r{^.*?#{Regexp.escape(gh_host)}\/(.*?)(\.git)?$}, '\1')
    end

    def self.extract_repo_url(env)
      return nil unless env.key? "CODEBUILD_SOURCE_REPO_URL"

      env["CODEBUILD_SOURCE_REPO_URL"].gsub(/\.git$/, "")
    end

    def self.extract_pr_url(env)
      return nil unless env.key? "CODEBUILD_SOURCE_VERSION"
      return nil unless env.key? "CODEBUILD_SOURCE_REPO_URL"
      return nil unless env["CODEBUILD_SOURCE_VERSION"].split("/").length == 2

      _source_origin, pr_number = env["CODEBUILD_SOURCE_VERSION"].split("/")
      github_repo_url = env["CODEBUILD_SOURCE_REPO_URL"].gsub(/\.git$/, "")

      "#{github_repo_url}/pull/#{pr_number}"
    end
  end
end
