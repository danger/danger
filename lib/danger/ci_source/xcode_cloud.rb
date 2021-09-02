require "danger/request_sources/github/github"

module Danger
  class XcodeCloud < CI
    def self.validates_as_ci?(env)
      env.key? "CI_XCODEBUILD_ACTION"
    end

    def self.validates_as_pr?(env)
      env.key? "CI_PULL_REQUEST_NUMBER"
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab, 
        Danger::RequestSources::BitbucketCloud, 
        Danger::RequestSources::BitbucketServer
      ]
    end

    def initialize(env)
      self.repo_slug = env["CI_PULL_REQUEST_SOURCE_REPO"]
      self.pull_request_id = env["CI_PULL_REQUEST_NUMBER"]
      self.repo_url = env["CI_PULL_REQUEST_HTML_URL"]
    end
  end
end
