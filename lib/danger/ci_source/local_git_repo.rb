# For more info see: https://github.com/schacon/ruby-git

require "git"
require "uri"

module Danger
  # ignore
  class LocalGitRepo < CI
    def self.validates_as_ci?(env)
      env.key? "DANGER_USE_LOCAL_GIT"
    end
    
    def self.validates_as_pr?(_env)
      true
    end

    def git
      @git ||= GitRepo.new
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env = {})
      # github_host = env["DANGER_GITHUB_HOST"] || "github.com"
      
      self.repo_slug = ""
      self.pull_request_id = ""
      self.repo_url = ""
    end
  end
end
