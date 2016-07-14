# https://semaphoreci.com/docs/available-environment-variables.html

module Danger
  module CISource
    # https://semaphoreci.com
    class Semaphore < CI
      def self.validates?(env)
        return false unless env["SEMAPHORE"]
        return false unless env["SEMAPHORE_REPO_SLUG"]
        return false unless env["PULL_REQUEST_NUMBER"].to_i > 0

        return true
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["SEMAPHORE_REPO_SLUG"]
        self.pull_request_id = env["PULL_REQUEST_NUMBER"]
        self.repo_url = GitRepo.new.origins # Semaphore doesn't provide a repo url env variable :/
      end
    end
  end
end
