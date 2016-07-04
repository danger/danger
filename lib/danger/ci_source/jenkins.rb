# https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-JenkinsSetEnvironmentVariables
# https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin

module Danger
  module CISource
    class Jenkins < CI
      def self.validates?(env)
        return false unless env['ghprbPullId'].to_i > 0
        return false unless env['GIT_URL']

        return true
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_url = env['GIT_URL']
        self.pull_request_id = env['ghprbPullId']

        repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/.]+)(?:.git)?$})
        self.repo_slug = repo_matches[2] unless repo_matches.nil?
      end
    end
  end
end
