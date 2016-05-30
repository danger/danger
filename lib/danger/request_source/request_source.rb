# coding: utf-8
require 'octokit'
require 'redcarpet'

module Danger
  module RequestSources

    class RequestSourceDSL
      def initialize(request_source)
        @request_source = request_source
      end

      # @!group PR Metadata
      # The title of the Pull Request
      # @return String
      #
      def pr_title
        ""
      end

      # @!group PR Metadata
      # The body text of the Pull Request
      # @return String
      #
      def pr_body
        ""
      end

      # @!group PR Metadata
      # The username of the author of the Pull Request
      # @return String
      #
      def pr_author
        ""
      end

      # @!group PR Metadata
      # The labels assigned to the Pull Request
      # @return [String]
      #
      def pr_labels
        ""
      end

      # @!group PR Commit Metadata
      # The branch to which the PR is going to be merged into
      # @return String
      #
      def branch_for_merge
        ""
      end

      # @!group PR Commit Metadata
      # The base commit to which the PR is going to be merged as a parent
      # @return String
      #
      def base_commit
        ""
      end

      # @!group PR Commit Metadata
      # The head commit to which the PR is requesting to be merged from
      # @return String
      #
      def head_commit
        ""
      end
    end

    class RequestSource
      attr_accessor :ci_source, :environment, :scm, :host, :dsl, :ignored_violations

      def initialize(ci_source, environment)
        raise "Subclass and overwrite initialize"
      end

      def validates?
        self.scm.origins.match(%r{#{Regexp.escape self.host}(:|/)(?<repo_slug>.+/.+?)(?:\.git)?$})
      end

      def scm
        @scm ||= nil
      end

      def host
        @host ||= nil
      end

      def dsl
        @dsl ||= RequestSourceDSL.new(self)
      end

      def ignored_violations
        @ignored_violations ||= []
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [])
        raise "Subclass and overwrite initialize"
      end

      def ensure_danger_branches_are_setup
        raise "Subclass and overwrite initialize"
      end

      def fetch_details
      end

    end
  end
end
