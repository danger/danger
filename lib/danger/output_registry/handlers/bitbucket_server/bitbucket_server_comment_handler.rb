# frozen_string_literal: true

require_relative "bitbucket_server_config"

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketServer
        # Posts violations as a consolidated PR comment on Bitbucket Server.
        #
        # This handler posts all violations as a single comment on the pull request.
        # When Code Insights is enabled, only non-inline violations are posted here
        # (inline violations go to Code Insights as annotations).
        #
        # @example
        #   handler = BitbucketServerCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class BitbucketServerCommentHandler < OutputHandler
          # Executes the handler to post PR comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::BitbucketServer)

            # Handle delete_old_comments
            if !new_comment? || remove_previous_comments?
              context.delete_old_comments(danger_id: danger_id)
            end

            # Get violations for main comment
            # If Code Insights is ready, use only main (non-inline) violations
            comment_violations = if code_insights_ready?
                                   context.main_violations_group(
                                     warnings: warnings,
                                     errors: errors,
                                     messages: messages,
                                     markdowns: markdowns
                                   )
                                 else
                                   { warnings: warnings, errors: errors, messages: messages, markdowns: markdowns }
                                 end

            comment_warnings = comment_violations[:warnings] || []
            comment_errors = comment_violations[:errors] || []
            comment_messages = comment_violations[:messages] || []
            comment_markdowns = comment_violations[:markdowns] || []

            has_comments = comment_warnings.count.positive? ||
                           comment_errors.count.positive? ||
                           comment_messages.count.positive? ||
                           comment_markdowns.count.positive?

            return unless has_comments

            # Generate comment body using context's method
            comment = context.generate_description(warnings: comment_warnings, errors: comment_errors)
            comment += "\n\n"
            comment += context.generate_comment(
              warnings: comment_warnings,
              errors: comment_errors,
              messages: comment_messages,
              markdowns: comment_markdowns,
              previous_violations: {},
              danger_id: danger_id,
              template: "bitbucket_server"
            )

            post_comment(comment)
          end

          protected

          # Checks if Code Insights API is ready.
          #
          # @return [Boolean] True if Code Insights is configured
          #
          def code_insights_ready?
            code_insights = context.instance_variable_get(:@code_insights)
            code_insights&.ready?
          end

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
