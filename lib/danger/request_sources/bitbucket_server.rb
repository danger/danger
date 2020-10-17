# coding: utf-8

require "danger/helpers/comments_helper"
require "danger/request_sources/bitbucket_server_api"
require "danger/request_sources/code_insights_api"
require_relative "request_source"

module Danger
  module RequestSources
    class BitbucketServer < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def self.env_vars
        [
          "DANGER_BITBUCKETSERVER_USERNAME",
          "DANGER_BITBUCKETSERVER_PASSWORD",
          "DANGER_BITBUCKETSERVER_HOST"
        ]
      end

      def self.optional_env_vars
        ["DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY",
         "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_TITLE",
         "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_DESCRIPTION",
         "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_LOGO_URL"
        ]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        project, slug = ci_source.repo_slug.split("/")
        @api = BitbucketServerAPI.new(project, slug, ci_source.pull_request_id, environment)
        @code_insights = CodeInsightsAPI.new(project, slug, environment)
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
        base_branch = self.pr_json[:toRef][:id].sub("refs/heads/", "")
        base_commit = self.pr_json[:toRef][:latestCommit]
        # Support for older versions of Bitbucket Server
        base_commit = self.pr_json[:toRef][:latestChangeset] if self.pr_json[:fromRef].key? :latestChangeset
        head_branch = self.pr_json[:fromRef][:id].sub("refs/heads/", "")
        head_commit = self.pr_json[:fromRef][:latestCommit]
        # Support for older versions of Bitbucket Server
        head_commit = self.pr_json[:fromRef][:latestChangeset] if self.pr_json[:fromRef].key? :latestChangeset

        # Next, we want to ensure that we have a version of the current branch at a known location
        scm.ensure_commitish_exists_on_branch! base_branch, base_commit
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        scm.ensure_commitish_exists_on_branch! head_branch, head_commit
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def organisation
        nil
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        delete_old_comments(danger_id: danger_id) if !new_comment || remove_previous_comments

        # If configured, send a Code Insights API to provide the PR with a quality report
        # which includes inline code violations found by Danger as Annotations.
        # If no inline violations occurred, an empty, successful (green) report will be sent.
        if @code_insights.ready?
          inline_violations = inline_violations_group(warnings: warnings, errors: errors, messages: messages)
          inline_warnings = inline_violations[:warnings] || []
          inline_errors = inline_violations[:errors] || []
          inline_messages = inline_violations[:messages] || []

          head_commit = self.pr_json[:fromRef][:latestCommit]
          @code_insights.send_report(head_commit,
                                     inline_warnings,
                                     inline_errors,
                                     inline_messages)
        end

        # If we're sending inline comments separately via Code Insights,
        # the main body comment should contain only generic, non-file specific messages.
        if @code_insights.ready?
          main_violations = main_violations_group(warnings: warnings, errors: errors, messages: messages)
          warnings = main_violations[:warnings] || []
          errors = main_violations[:errors] || []
          messages = main_violations[:messages] || []
          markdowns = main_violations[:markdowns] || []
        end

        comment = generate_description(warnings: warnings,
                                       errors: errors)
        comment += "\n\n"
        comment += generate_comment(warnings: warnings,
                                    errors: errors,
                                    messages: messages,
                                    markdowns: markdowns,
                                    previous_violations: {},
                                    danger_id: danger_id,
                                    template: "bitbucket_server")
        @api.post_comment(comment)
      end

      def delete_old_comments(danger_id: "danger")
        @api.fetch_last_comments.each do |c|
          @api.delete_comment(c[:id], c[:version]) if c[:text] =~ /generated_by_#{danger_id}/
        end
      end

      def main_violations_group(warnings: [], errors: [], messages: [], markdowns: [])
        {
          warnings: warnings.reject(&:inline?),
          errors: errors.reject(&:inline?),
          messages: messages.reject(&:inline?),
          markdowns: markdowns.reject(&:inline?)
        }
      end

      def inline_violations_group(warnings: [], errors: [], messages: [], markdowns: [])
        cmp = proc do |a, b|
          next -1 unless a.file && a.line
          next 1 unless b.file && b.line

          next a.line <=> b.line if a.file == b.file
          next a.file <=> b.file
        end

        # Sort to group inline comments by file
        {
          warnings: warnings.select(&:inline?).sort(&cmp),
          errors: errors.select(&:inline?).sort(&cmp),
          messages: messages.select(&:inline?).sort(&cmp),
          markdowns: markdowns.select(&:inline?).sort(&cmp)
        }
      end

      def update_pr_build_status(status, build_job_link, description)
        changeset = self.pr_json[:fromRef][:latestCommit]
        # Support for older versions of Bitbucket Server
        changeset = self.pr_json[:fromRef][:latestChangeset] if self.pr_json[:fromRef].key? :latestChangeset
        puts "Changeset: " + changeset
        puts self.pr_json.to_json
        @api.update_pr_build_status(status, changeset, build_job_link, description)
      end
    end
  end
end
