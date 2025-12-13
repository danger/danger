# frozen_string_literal: true

require_relative "github_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts violations as a consolidated PR comment.
        #
        # This handler extracts violations and posts them as a single comment
        # on the pull request. It manages comment lifecycle including creation,
        # updates, and deletion based on configuration.
        #
        # @example
        #   handler = GitHubCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitHubCommentHandler < OutputHandler
          # Executes the handler to post PR comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?

            request_source = context.env.request_source
            return unless request_source.kind_of?(::Danger::RequestSources::GitHub)

            # Get violations for comment (non-inline only)
            comment_violations = filter_comment_violations

            # Generate comment body
            comment_body = generate_comment_body(comment_violations)
            return if comment_body.nil? || comment_body.empty?

            # Post or update the comment
            post_or_update_comment(request_source, comment_body)
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

            body = "Danger has reviewed this PR:\n\n"

            if violations[:errors].any?
              body += "## 🚫 Errors\n\n"
              violations[:errors].each do |error|
                body += "- #{error.message}\n"
              end
              body += "\n"
            end

            if violations[:warnings].any?
              body += "## ⚠️ Warnings\n\n"
              violations[:warnings].each do |warning|
                body += "- #{warning.message}\n"
              end
              body += "\n"
            end

            if violations[:messages].any?
              body += "## 💬 Messages\n\n"
              violations[:messages].each do |message|
                body += "- #{message.message}\n"
              end
            end

            body
          end

          # Posts or updates the comment on the PR.
          #
          # @param request_source [Danger::RequestSources::GitHub] The GitHub request source
          # @param comment_body [String] The comment body
          # @return [void]
          #
          def post_or_update_comment(request_source, comment_body)
            client = request_source.client
            pr_number = request_source.pr_json["number"]

            existing_comments = client.issue_comments(
              request_source.repo_slug,
              pr_number
            )

            previous_comment = existing_comments.find do |comment|
              comment.body.include?("Danger has reviewed this PR")
            end

            if previous_comment
              client.update_issue_comment(
                request_source.repo_slug,
                previous_comment.id,
                comment_body
              )
            else
              client.add_comment(
                request_source.repo_slug,
                pr_number,
                comment_body
              )
            end
          rescue StandardError => e
            log_warning("Failed to post comment: #{e.message}")
          end
        end
      end
    end
  end
end
