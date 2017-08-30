# coding: utf-8

require "danger/helpers/comments_helper"
require "danger/request_sources/vsts_api"

module Danger
  module RequestSources
    class VSTS < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def self.env_vars
        [
          "SECRET_DANGER_VSTS_API_TOKEN",
          "DANGER_VSTS_HOST"
        ]
      end

      def self.optional_env_vars
        [
          "DANGER_VSTS_API_VERSION"
        ]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        project, slug = ci_source.repo_slug.split("/")
        @api = VSTSAPI.new(project, slug, ci_source.pull_request_id, environment)
      end

      def validates_as_ci?
        # TODO: ???
        true
      end

      def validates_as_api_source?
        @api.credentials_given?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host ||= @api.host
      end

      def fetch_details
        self.pr_json = @api.fetch_pr_json
      end

      def setup_danger_branches
        base_commit = self.pr_json[:lastMergeTargetCommit][:commitId]
        head_commit = self.pr_json[:lastMergeSourceCommit][:commitId]

        # Next, we want to ensure that we have a version of the current branch at a known location
        scm.ensure_commitish_exists! base_commit
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        scm.ensure_commitish_exists! head_commit
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def organisation
        nil
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false)
        unless @api.supports_comments?
          return
        end

        delete_old_comments(danger_id: danger_id) unless new_comment

        comment = generate_description(warnings: warnings, errors: errors)
        comment += "\n\n"
        comment += generate_comment(warnings: warnings,
                                     errors: errors,
                                   messages: messages,
                                  markdowns: markdowns,
                        previous_violations: {},
                                  danger_id: danger_id,
                                   template: "vsts")

        @api.post_comment(comment)
      end

      def delete_old_comments(danger_id: "danger")
        @api.fetch_last_comments.each do |c|
          thread_id = c[:id]
          comment = c[:comments].first
          comment_id = comment[:id]
          comment_content = comment[:content].nil? ? "" : comment[:content]

          @api.delete_comment(thread_id, comment_id) if comment_content.include?("generated_by_#{danger_id}")
        end
      end
    end
  end
end
