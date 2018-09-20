# coding: utf-8

require "danger/helpers/comments_helper"
require "danger/helpers/comment"

module Danger
  module RequestSources
    class LocalOnly < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :mr_json, :commits_json

      def self.env_vars
        ["DANGER_LOCAL_ONLY"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment
      end

      def validates_as_ci?
        true
      end

      def validates_as_api_source?
        true
      end

      def scm
        @scm ||= GitRepo.new
      end

      def setup_danger_branches
        # Check that discovered values really exists
        [ci_source.base_commit, ci_source.head_commit].each do |commit|
          raise "Specified commit '#{commit}' not found" if scm.exec("rev-parse --quiet --verify #{commit}").empty?
        end

        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{ci_source.base_commit}"
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{ci_source.head_commit}"
      end

      def fetch_details; end

      def update_pull_request!(_hash_needed); end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        nil
      end
    end
  end
end
