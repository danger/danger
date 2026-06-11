# frozen_string_literal: true

require_relative "vsts_config"

module Danger
  module OutputRegistry
    module Handlers
      module VSTS
        # Posts violations as PR comments on VSTS (Azure DevOps).
        #
        # This handler posts violations as comments on the pull request,
        # handling both inline comments and main PR comments. It uses
        # context methods to maintain test compatibility.
        #
        # @example
        #   handler = VSTSCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class VSTSCommentHandler < OutputHandler
          # Executes the handler to post PR comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::VSTS)
            return unless api_supports_comments?

            # Separate regular and inline violations
            regular_violations = context.send(:regular_violations_group,
                                              warnings: warnings,
                                              errors: errors,
                                              messages: messages,
                                              markdowns: markdowns)

            inline_violations = context.send(:inline_violations_group,
                                             warnings: warnings,
                                             errors: errors,
                                             messages: messages,
                                             markdowns: markdowns)

            # Submit inline comments and get remaining violations
            rest_inline_violations = context.submit_inline_comments!(
              warnings: inline_violations[:warnings],
              errors: inline_violations[:errors],
              messages: inline_violations[:messages],
              markdowns: inline_violations[:markdowns],
              previous_violations: {},
              danger_id: danger_id
            )

            # Merge regular violations with those that couldn't be posted inline
            main_violations = context.send(:merge_violations,
                                           regular_violations, rest_inline_violations)

            # Generate comment body
            comment = context.generate_description(
              warnings: main_violations[:warnings],
              errors: main_violations[:errors]
            )
            comment += "\n\n"
            comment += context.generate_comment(
              warnings: main_violations[:warnings],
              errors: main_violations[:errors],
              messages: main_violations[:messages],
              markdowns: main_violations[:markdowns],
              previous_violations: {},
              danger_id: danger_id,
              template: "vsts"
            )

            # Post or update comment based on options
            if new_comment? || remove_previous_comments?
              context.post_new_comment(comment)
            else
              context.update_old_comment(comment, danger_id: danger_id)
            end
          end

          protected

          # Checks if the API supports comments.
          #
          # @return [Boolean] True if API supports comments
          #
          def api_supports_comments?
            api = context.instance_variable_get(:@api)
            api&.supports_comments?
          end
        end
      end
    end
  end
end
