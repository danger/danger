module Danger
  module CISource
    # "abstract" CI class
    class CI
      attr_accessor :repo_slug, :pull_request_id, :supported_request_sources

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def supports?(request_source)
        supported_request_sources.include? request_source
      end

      def self.validates?(_env)
        false
      end

      def initialize(_env)
        raise "Subclass and overwrite initialize"
      end
    end
  end
end
