# frozen_string_literal: true

require_relative "bitbucket_server_config"

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketServer
        # Sends inline violations to Bitbucket Server Code Insights API.
        #
        # This handler posts inline violations as annotations via the Code Insights
        # API, providing a quality report on the PR. If no inline violations exist,
        # an empty successful (green) report is sent.
        #
        # Requires Code Insights API to be configured via environment variables:
        # - DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY
        # - DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_TITLE (optional)
        # - DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_DESCRIPTION (optional)
        # - DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_LOGO_URL (optional)
        #
        # @example
        #   handler = BitbucketServerCodeInsightsHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class BitbucketServerCodeInsightsHandler < OutputHandler
          # Executes the handler to send Code Insights report.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::BitbucketServer)
            return unless code_insights_ready?

            # Get inline violations for Code Insights
            inline_violations = context.inline_violations_group(
              warnings: warnings,
              errors: errors,
              messages: messages
            )

            inline_warnings = inline_violations[:warnings] || []
            inline_errors = inline_violations[:errors] || []
            inline_messages = inline_violations[:messages] || []

            # Get head commit for the report
            head_commit = context.pr_json[:fromRef][:latestCommit]

            # Send the Code Insights report
            send_report(head_commit, inline_warnings, inline_errors, inline_messages)
          end

          protected

          # Checks if Code Insights API is ready.
          #
          # @return [Boolean] True if Code Insights is configured
          #
          def code_insights_ready?
            code_insights&.ready?
          end

          # Sends the Code Insights report.
          #
          # @param head_commit [String] The commit hash
          # @param inline_warnings [Array] Warning violations
          # @param inline_errors [Array] Error violations
          # @param inline_messages [Array] Message violations
          # @return [void]
          #
          def send_report(head_commit, inline_warnings, inline_errors, inline_messages)
            code_insights.send_report(
              head_commit,
              inline_warnings,
              inline_errors,
              inline_messages
            )
          rescue StandardError => e
            log_warning("Failed to send Code Insights report: #{e.message}")
          end

          private

          # Gets the Code Insights API instance.
          #
          # @return [CodeInsightsAPI, nil]
          #
          def code_insights
            context.instance_variable_get(:@code_insights)
          end
        end
      end
    end
  end
end
