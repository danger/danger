# https://circleci.com/docs/environment-variables
require "uri"

module Danger
  # ### CI Setup
  #
  class BitbucketPipeline < CI

    def self.validates_as_ci?(env)
      env.key? "BITBUCKET_BUILD_NUMBER"
    end

    def self.validates_as_pr?(env)
      env.key? "BITBUCKET_PR_ID"
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::BitbucketCloud]
    end

    def initialize(env)
      self.repo_url = env["BITBUCKET_GIT_HTTP_ORIGIN"]
      self.repo_slug = "#{env["BITBUCKET_REPO_OWNER"]}/#{env["BITBUCKET_REPO_SLUG"]}"
      self.pull_request_id = env["BITBUCKET_PR_ID"]
    end
  end
end
