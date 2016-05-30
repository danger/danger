# https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-JenkinsSetEnvironmentVariables
# https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin

module Danger
  module CISource
    class Jenkins < CI
      def self.validates?(env)
        return !env["ghprbPullId"].nil? && !env["GIT_URL"].nil?
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        repo = env["GIT_URL"]
        unless repo.nil?
          repo_matches = repo.match(%r{([\/:])([^\/]+\/[^\/.]+)(?:.git)?$})
          self.repo_slug = repo_matches[2] unless repo_matches.nil?
        end

        # from https://docs.travis-ci.com/user/pull-requests, as otherwise it's "false"
        if env["ghprbPullId"].to_i > 0
          self.pull_request_id = env["ghprbPullId"]
        end
      end
    end
  end
end
