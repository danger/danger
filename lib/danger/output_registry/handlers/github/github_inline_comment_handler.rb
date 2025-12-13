# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts inline comments on specific file lines in a GitHub PR.
        #
        # This handler posts violations as inline comments on the PR,
        # matching violations to the specific file and line they reference.
        #
        # @example
        #   handler = GitHubInlineCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitHubInlineCommentHandler < OutputHandler
          # Executes the handler to post inline comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?

            request_source = context.env.request_source
            return unless request_source.kind_of?(::Danger::RequestSources::GitHub)

            # Filter to inline violations (those with file and line)
            inline_violations = filter_inline_violations

            return if inline_violations.values.all?(&:empty?)

            # Post inline comments
            post_inline_comments(request_source, inline_violations)
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
          # @param request_source [Danger::RequestSources::GitHub] The GitHub request source
          # @param violations [Hash] Violations with file/line info
          # @return [void]
          #
          def post_inline_comments(request_source, violations)
            client = request_source.client
            pr_number = request_source.pr_json["number"]
            repo_slug = request_source.repo_slug

            all_violations = [violations[:errors], violations[:warnings], violations[:messages]].flatten.compact

            all_violations.each do |violation|
              body = "#{violation.message} (#{violation_type_emoji(violation.type)})"

              client.create_pull_request_review_comment(
                repo_slug,
                pr_number,
                body,
                request_source.pr_json["head"]["sha"],
                violation.file,
                violation.line
              )
            rescue StandardError => e
              # Log but continue with other violations
              log_warning("Failed to post inline comment: #{e.message}")
            end
          end

          # Determines the emoji for a violation type.
          #
          # @param type [Symbol] Violation type (:error, :warning, :message)
          # @return [String] Emoji representation
          #
          def violation_type_emoji(type)
            case type
            when :error then "🚫"
            when :warning then "⚠️"
            else "💬"
            end
          end
        end
      end
    end
  end
end
