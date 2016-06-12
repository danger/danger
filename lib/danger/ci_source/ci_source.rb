require 'set'

module Danger
  module CISource
    # "abstract" CI class
    class CI
      attr_accessor :repo_slug, :pull_request_id, :repo_url, :supported_request_sources

      def self.inherited(child_class)
        available_ci_sources.add child_class
        super
      end

      def self.available_ci_sources
        @available_ci_sources ||= Set.new
      end

      def supported_request_sources
        raise "CISource subclass must specify the supported request sources"
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
