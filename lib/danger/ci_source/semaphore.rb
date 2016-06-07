# https://semaphoreci.com/docs/available-environment-variables.html

module Danger
  module CISource
    class Semaphore < CI
      def self.validates?(env)
        return !env["SEMAPHORE"].nil?
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def initialize(env)
        self.repo_slug = env["SEMAPHORE_REPO_SLUG"]
        if env["PULL_REQUEST_NUMBER"].to_i > 0
          self.pull_request_id = env["PULL_REQUEST_NUMBER"]
        end
      end
    end
  end
end
