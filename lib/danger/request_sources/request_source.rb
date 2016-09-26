module Danger
  module RequestSources
    class RequestSource
      DANGER_REPO_NAME = "danger".freeze

      attr_accessor :ci_source, :environment, :scm, :host, :ignored_violations

      def self.env_vars
        raise "Subclass and overwrite self.env_vars"
      end

      def self.optional_env_vars
        []
      end

      def self.inherited(child_class)
        available_request_sources.add child_class
        super
      end

      def self.available_request_sources
        @available_request_sources ||= Set.new
      end

      def self.source_name
        to_s.sub("Danger::RequestSources::".freeze, "".freeze)
      end

      def self.available_source_names_and_envs
        available_request_sources.map do |klass|
          " - #{klass.source_name}: #{klass.env_vars.join(', '.freeze).yellow}"
        end
      end

      def initialize(_ci_source, _environment)
        raise "Subclass and overwrite initialize"
      end

      # @return [Boolean] whether scm.origins is a valid git repository or not
      def validates_as_ci?
        !!self.scm.origins.match(%r{#{Regexp.escape self.host}(:|/)(.+/.+?)(?:\.git)?$})
      end

      def validates_as_api_source?
        raise "Subclass and overwrite validates_as_api_source?"
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

      def organisation
        raise "Subclass and overwrite organisation"
      end

      def file_url(_organisation: nil, _repository: nil, _branch: "master", _path: nil)
        raise "Subclass and overwrite file_url"
      end
    end
  end
end
