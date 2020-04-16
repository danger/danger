# coding: utf-8

require "danger/helpers/comments_helper"
require "danger/request_sources/bitbucket_cloud_api"
require "danger/danger_core/message_group"

module Danger
  module RequestSources
    class BitbucketCloud < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def self.env_vars
        [
          "DANGER_BITBUCKETCLOUD_USERNAME",
          "DANGER_BITBUCKETCLOUD_UUID",
          "DANGER_BITBUCKETCLOUD_PASSWORD"
        ]
      end

      def self.optional_env_vars
        ["DANGER_BITBUCKETCLOUD_OAUTH_KEY", "DANGER_BITBUCKETCLOUD_OAUTH_SECRET"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        @api = BitbucketCloudAPI.new(ci_source.repo_slug, ci_source.pull_request_id, nil, environment)
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
        base_branch = self.pr_json[:destination][:branch][:name]
        base_commit = self.pr_json[:destination][:commit][:hash]
        head_branch = self.pr_json[:source][:branch][:name]
        head_commit = self.pr_json[:source][:commit][:hash]

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

        comment = generate_description(warnings: warnings, errors: errors, template: "bitbucket_server")
        comment += "\n\n"

        warnings = update_inline_comments_for_kind!(:warnings, warnings, danger_id: danger_id)
        errors = update_inline_comments_for_kind!(:errors, errors, danger_id: danger_id)
        messages = update_inline_comments_for_kind!(:messages, messages, danger_id: danger_id)
        markdowns = update_inline_comments_for_kind!(:markdowns, markdowns, danger_id: danger_id)

        comment += generate_comment(warnings: warnings,
                                    errors: errors,
                                    messages: messages,
                                    markdowns: markdowns,
                                    previous_violations: {},
                                    danger_id: danger_id,
                                    template: "bitbucket_server")

        @api.post_comment(comment)
      end

      def update_pr_by_line!(message_groups:,
                             danger_id: "danger",
                             new_comment: false,
                             remove_previous_comments: false)
        if !new_comment || remove_previous_comments
          delete_old_comments(danger_id: danger_id)
        end

        summary_body = generate_description(warnings: message_groups.fake_warnings_array,
                                            errors: message_groups.fake_errors_array,
                                            template: "bitbucket_server")
        summary_body += "\n\n"


        # this isn't the most elegant thing in the world, but we need the group
        # with file: nil, line: nil so we can combine its info in with the
        # summary_body
        summary_group = message_groups.first
        if summary_group && summary_group.file.nil? && summary_group.line.nil?
          # remove summary_group from message_groups so it doesn't get a
          # duplicate comment posted in the message_groups loop below
          message_groups.shift
        else
          summary_group = MessageGroup.new(file: nil, line: nil)
        end

        summary_body += generate_message_group_comment(
          message_group: summary_group,
          danger_id: danger_id,
          template: "bitbucket_server_message_group"
        )

        @api.post_comment(summary_body)

        message_groups.each do |message_group|
          body = generate_message_group_comment(message_group: message_group,
                                                danger_id: danger_id,
                                                template: "bitbucket_server_message_group")
          @api.post_comment(body,
                            file: message_group.file,
                            line: message_group.line)
        end
      end

      def update_inline_comments_for_kind!(kind, messages, danger_id: "danger")
        emoji = { warnings: "warning", errors: "no_entry_sign", messages: "book" }[kind]

        messages.reject do |message|
          next false unless message.file && message.line

          body = ""

          if kind == :markdown
            body = generate_inline_markdown_body(message,
                                                danger_id: danger_id,
                                                template: "bitbucket_server")
          else
            body = generate_inline_comment_body(emoji, message,
                                                danger_id: danger_id,
                                                template: "bitbucket_server")
          end

          @api.post_comment(body, file: message.file, line: message.line)

          true
        end
      end

      def delete_old_comments(danger_id: "danger")
        @api.fetch_comments.each do |c|
          next if c[:user][:uuid] != @api.my_uuid
          @api.delete_comment(c[:id]) if c[:content][:raw] =~ /generated_by_#{danger_id}/
        end
      end
    end
  end
end
