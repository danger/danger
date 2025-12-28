# frozen_string_literal: true

require_relative "github_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts violations as a consolidated PR comment.
        #
        # This handler posts all violations as a single comment on the pull request.
        # It manages comment lifecycle including creation, updates, and deletion
        # based on configuration options.
        #
        # Supports the following options:
        # - danger_id: Identifier to distinguish Danger comments (default: "danger")
        # - new_comment: Always create a new comment instead of updating (default: false)
        # - remove_previous_comments: Delete all previous Danger comments (default: false)
        # - markdowns: Additional markdown content to include
        #
        # @example
        #   handler = GitHubCommentHandler.new(context, violations, danger_id: "my-danger")
        #   handler.execute if handler.enabled?
        #
        class GitHubCommentHandler < OutputHandler
          # Executes the handler to post PR comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::GitHub)

            comment_violations = filter_comment_violations
            comment_markdowns = filter_comment_markdowns

            # Handle remove_previous_comments option
            if remove_previous_comments?
              delete_old_comments!
              return if comment_violations.values.all?(&:empty?) && comment_markdowns.empty?
            end

            # Find existing Danger comments
            existing_comments = find_danger_comments
            last_comment = existing_comments.last
            should_create_new = new_comment? || last_comment.nil? || remove_previous_comments?

            # Parse previous violations for comparison
            previous_violations = if should_create_new
                                    {}
                                  else
                                    context.parse_comment(last_comment.body)
                                  end

            # Check if there's anything to post
            if comment_violations.values.all?(&:empty?) && comment_markdowns.empty?
              # No violations, delete old comments if they exist
              delete_old_comments! unless existing_comments.empty?
              return
            end

            # Generate comment body using context's method (for test compatibility)
            comment_body = context.generate_comment(
              warnings: comment_violations[:warnings],
              errors: comment_violations[:errors],
              messages: comment_violations[:messages],
              markdowns: comment_markdowns,
              previous_violations: previous_violations,
              danger_id: danger_id,
              template: "github"
            )

            post_or_update_comment(comment_body, last_comment, should_create_new)
          end

          protected

          # Filters violations suitable for PR comment (non-inline).
          #
          # Includes:
          # - Violations without file/line info (always go to main comment)
          # - Out-of-range violations reported by the inline handler
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_comment_violations
            non_inline = filter_violations { |v| v.file.nil? || v.line.nil? }

            # Include out-of-range violations from inline handler
            oor = out_of_range_violations
            {
              warnings: non_inline[:warnings] + (oor[:warnings] || []),
              errors: non_inline[:errors] + (oor[:errors] || []),
              messages: non_inline[:messages] + (oor[:messages] || [])
            }
          end

          # Filters markdowns suitable for PR comment (non-inline).
          #
          # Includes:
          # - Markdowns without file/line info (always go to main comment)
          # - Out-of-range markdowns reported by the inline handler
          #
          # @return [Array] Array of non-inline markdowns
          #
          def filter_comment_markdowns
            non_inline = markdowns.select { |m| m.file.nil? || m.line.nil? }
            non_inline + out_of_range_markdowns
          end

          # Finds all Danger comments on the PR.
          #
          # @return [Array<Comment>] Array of Danger-generated comments
          #
          def find_danger_comments
            context.issue_comments.select { |comment| comment.generated_by_danger?(danger_id) }
          end

          # Deletes all old Danger comments on the PR.
          #
          # @param except [Integer, nil] Comment ID to preserve
          # @return [void]
          #
          def delete_old_comments!(except: nil)
            find_danger_comments.each do |comment|
              next if comment.id == except

              context.client.delete_comment(context.ci_source.repo_slug, comment.id)
            end
          rescue StandardError => e
            log_warning("Failed to delete old comments: #{e.message}")
          end

          # Posts a new comment or updates an existing one.
          #
          # @param comment_body [String] The comment body
          # @param last_comment [Comment, nil] Last existing Danger comment
          # @param should_create_new [Boolean] Whether to create new comment
          # @return [void]
          #
          def post_or_update_comment(comment_body, last_comment, should_create_new)
            if should_create_new
              context.client.add_comment(
                context.ci_source.repo_slug,
                context.ci_source.pull_request_id,
                comment_body
              )
            else
              context.client.update_comment(
                context.ci_source.repo_slug,
                last_comment.id,
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
