require "danger/helpers/comments_helper"
require "danger/request_sources/bitbucket_server_api"
require "danger/request_sources/code_insights_api"
require "danger/output_registry/output_handler_registry"
require_relative "request_source"

module Danger
  module RequestSources
    class BitbucketServer < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json, :dismiss_out_of_range_messages

      def self.env_vars
        [
          "DANGER_BITBUCKETSERVER_USERNAME",
          "DANGER_BITBUCKETSERVER_PASSWORD",
          "DANGER_BITBUCKETSERVER_HOST"
        ]
      end

      def self.optional_env_vars
        [
          "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY",
          "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_TITLE",
          "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_DESCRIPTION",
          "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_LOGO_URL",
          "DANGER_BITBUCKETSERVER_VERIFY_SSL",
          "DANGER_BITBUCKETSERVER_DISMISS_OUT_OF_RANGE_MESSAGES"
        ]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.dismiss_out_of_range_messages = environment["DANGER_BITBUCKETSERVER_DISMISS_OUT_OF_RANGE_MESSAGES"] == "true"

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

      def pr_diff
        @pr_diff ||= @api.fetch_pr_diff
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

      # Sending data to Bitbucket Server
      #
      # Delegates to the OutputHandlerRegistry which executes the appropriate
      # handlers for Bitbucket Server (Code Insights, comment).
      #
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        OutputRegistry::OutputHandlerRegistry.execute_for_request_source(
          self,
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns,
          danger_id: danger_id,
          new_comment: new_comment,
          remove_previous_comments: remove_previous_comments
        )
      end

      def delete_old_comments(danger_id: "danger")
        @api.fetch_last_comments.each do |c|
          @api.delete_comment(c[:id], c[:version]) if c[:text] =~ /generated_by_#{danger_id}/
        end
      end

      def main_violations_group(warnings: [], errors: [], messages: [], markdowns: [])
        if dismiss_out_of_range_messages
          {
            warnings: warnings.reject(&:inline?),
            errors: errors.reject(&:inline?),
            messages: messages.reject(&:inline?),
            markdowns: markdowns.reject(&:inline?)
          }
        else
          in_diff = proc { |a| find_position_in_diff?(a.file, a.line) }
          {
            warnings: warnings.reject(&in_diff),
            errors: errors.reject(&in_diff),
            messages: messages.reject(&in_diff),
            markdowns: markdowns.reject(&in_diff)
          }
        end
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
        puts "Changeset: #{changeset}"
        puts self.pr_json.to_json
        @api.update_pr_build_status(status, changeset, build_job_link, description)
      end

      def find_position_in_diff?(file, line)
        return nil if file.nil? || line.nil?
        return nil if file.empty?

        added_lines(file).include?(line)
      end

      def file_diff(file)
        self.pr_diff[:diffs].find { |diff| diff[:destination] && diff[:destination][:toString] == file } || { hunks: [] }
      end

      def added_lines(file)
        @added_lines ||= {}
        @added_lines[file] ||= file_diff(file)[:hunks].map do |hunk|
          hunk[:segments].select { |segment| segment[:type] == "ADDED" }.map do |segment|
            segment[:lines].map do |line|
              line[:destination]
            end
          end
        end.flatten
      end
    end
  end
end
