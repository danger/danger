# frozen_string_literal: true

require_relative "bitbucket_cloud_config"

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketCloud
        # Posts inline comments on specific file lines in a Bitbucket Cloud PR.
        #
        # This handler posts violations as inline comments on the PR,
        # matching violations to the specific file and line they reference.
        #
        # @example
        #   handler = BitbucketCloudInlineCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class BitbucketCloudInlineCommentHandler < OutputHandler
          # Executes the handler to post inline comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?
            return unless context.kind_of?(::Danger::RequestSources::BitbucketCloud)

            inline_violations = filter_inline_violations
            return if inline_violations.values.all?(&:empty?)

            post_inline_comments(inline_violations)
          end

          protected

          # Filters violations that have file and line information.
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_inline_violations
            filter_violations { |v| v.file && v.line }
          end

          # Posts inline comments to the PR.
          #
          # @param violations [Hash] Violations with file/line info
          # @return [void]
          #
          def post_inline_comments(violations)
            api = context.instance_variable_get(:@api)
            violations_list = violations[:errors] + violations[:warnings] + violations[:messages]

            violations_list.each do |violation|
              emoji = BitbucketCloudConfig::TYPE_MAPPINGS[violation.type][:emoji]
              body = ":#{emoji}: #{violation.message}\n\n#{BitbucketCloudConfig::PR_REVIEW_HEADER}"

              api.post_comment(body, file: violation.file, line: violation.line)
            rescue StandardError => e
              log_warning("Failed to post inline comment: #{e.message}")
            end
          end
        end
      end
    end
  end
end
