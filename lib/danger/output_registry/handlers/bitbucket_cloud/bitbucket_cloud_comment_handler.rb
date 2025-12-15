# frozen_string_literal: true

require_relative "bitbucket_cloud_config"

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketCloud
        # Posts violations as a consolidated PR comment.
        #
        # This handler extracts violations and posts them as a single comment
        # on the pull request.
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
            return unless has_violations?
            return unless context.kind_of?(::Danger::RequestSources::BitbucketCloud)

            comment_violations = filter_comment_violations
            comment_body = generate_comment_body(comment_violations)
            return if comment_body.nil? || comment_body.empty?

            post_comment(comment_body)
          end

          protected

          # Filters violations suitable for PR comment (non-inline).
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_comment_violations
            filter_violations { |v| v.file.nil? }
          end

          # Generates the comment body.
          #
          # @param violations [Hash] Violations to include in comment
          # @return [String, nil] Comment body, or nil if no violations
          #
          def generate_comment_body(violations)
            return nil if violations.values.all?(&:empty?)

            parts = []

            if violations[:errors].any?
              parts << "## :no_entry_sign: #{BitbucketCloudConfig::ERRORS_SECTION_TITLE}"
              parts << ""
              violations[:errors].each { |error| parts << "- #{error.message}" }
              parts << ""
            end

            if violations[:warnings].any?
              parts << "## :warning: #{BitbucketCloudConfig::WARNINGS_SECTION_TITLE}"
              parts << ""
              violations[:warnings].each { |warning| parts << "- #{warning.message}" }
              parts << ""
            end

            if violations[:messages].any?
              parts << "## :book: #{BitbucketCloudConfig::MESSAGES_SECTION_TITLE}"
              parts << ""
              violations[:messages].each { |message| parts << "- #{message.message}" }
              parts << ""
            end

            parts << BitbucketCloudConfig::PR_REVIEW_HEADER

            parts.join("\n")
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
