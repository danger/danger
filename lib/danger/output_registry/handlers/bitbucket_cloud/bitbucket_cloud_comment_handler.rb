# frozen_string_literal: true

require_relative "bitbucket_cloud_config"

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketCloud
        # Posts violations as a consolidated PR comment.
        #
        # This handler extracts violations and posts them as a single comment
        # on the pull request. It handles deletion of old comments and
        # posts new comments as needed.
        #
        # @example
        #   handler = BitbucketCloudCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class BitbucketCloudCommentHandler < OutputHandler
          # Executes the handler to post PR comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::BitbucketCloud)

            # Handle delete_old_comments (similar to original behavior)
            if !new_comment? || remove_previous_comments?
              context.delete_old_comments(danger_id: danger_id)
            end

            # Update inline comments and get remaining violations
            # This modifies violations in-place and returns non-inline ones
            remaining_warnings = context.update_inline_comments_for_kind!(:warnings, warnings, danger_id: danger_id)
            remaining_errors = context.update_inline_comments_for_kind!(:errors, errors, danger_id: danger_id)
            remaining_messages = context.update_inline_comments_for_kind!(:messages, messages, danger_id: danger_id)
            remaining_markdowns = context.update_inline_comments_for_kind!(:markdowns, markdowns, danger_id: danger_id)

            has_comments = remaining_warnings.count.positive? ||
                           remaining_errors.count.positive? ||
                           remaining_messages.count.positive? ||
                           remaining_markdowns.count.positive?

            return unless has_comments

            # Generate comment body using context's method
            comment = context.generate_description(warnings: remaining_warnings, errors: remaining_errors, template: "bitbucket_server")
            comment += "\n\n"
            comment += context.generate_comment(
              warnings: remaining_warnings,
              errors: remaining_errors,
              messages: remaining_messages,
              markdowns: remaining_markdowns,
              previous_violations: {},
              danger_id: danger_id,
              template: "bitbucket_server"
            )

            post_comment(comment)
          end

          protected

          # Posts the comment to the PR.
          #
          # @param comment_body [String] The comment body
          # @return [void]
          #
          def post_comment(comment_body)
            api = context.instance_variable_get(:@api)
            api.post_comment(comment_body)
          rescue StandardError => e
            log_warning("Failed to post comment: #{e.message}")
          end
        end
      end
    end
  end
end
