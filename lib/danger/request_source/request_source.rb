module Danger
  module RequestSources
    class RequestSource
      attr_accessor :ci_source, :environment, :scm, :host, :ignored_violations

      def self.inherited(child_class)
        available_request_sources.add child_class
        super
      end

      def self.available_request_sources
        @available_request_sources ||= Set.new
      end

      def initialize(_ci_source, _environment)
        raise "Subclass and overwrite initialize"
      end

      def validates?
        !!self.scm.origins.match(%r{#{Regexp.escape self.host}(:|/)(?<repo_slug>.+/.+?)(?:\.git)?$})
      end

      def scm
        @scm ||= nil
      end

      def host
        @host ||= nil
      end

      def ignored_violations
        @ignored_violations ||= []
      end

      def update_pull_request!(_warnings: [], _errors: [], _messages: [], _markdowns: [])
        raise "Subclass and overwrite update_pull_request!"
      end

      def setup_danger_branches
        raise "Subclass and overwrite setup_danger_branches"
      end

      def fetch_details
        raise "Subclass and overwrite initialize"
      end
    end
  end
end
