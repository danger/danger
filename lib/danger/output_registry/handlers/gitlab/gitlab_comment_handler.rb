# frozen_string_literal: true

require_relative "gitlab_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitLab
        # Posts violations as a consolidated MR comment (note).
        #
        # This handler extracts violations and posts them as a single comment
        # on the merge request. It manages comment lifecycle including creation,
        # updates, and deletion.
        #
        # @example
        #   handler = GitLabCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitLabCommentHandler < OutputHandler
          # Executes the handler to post MR comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::GitLab)

            comment_violations = filter_comment_violations
            comment_markdowns = filter_comment_markdowns

            # Find existing Danger comments (non-inline)
            existing_comments = find_danger_comments
            last_comment = existing_comments.last
            should_create_new = new_comment? || last_comment.nil? || remove_previous_comments?

            # Parse previous violations for comparison
            previous_violations = if should_create_new
                                    {}
                                  else
                                    context.parse_comment(last_comment.body)
                                  end

            # Handle remove_previous_comments
            if remove_previous_comments?
              delete_old_comments!
            end

            # Check if there's anything to post
            if comment_violations.values.all?(&:empty?) && comment_markdowns.empty?
              delete_old_comments! unless existing_comments.empty?
              return
            end

            # Generate comment body using context's method
            comment_body = context.generate_comment(
              warnings: comment_violations[:warnings],
              errors: comment_violations[:errors],
              messages: comment_violations[:messages],
              markdowns: comment_markdowns,
              previous_violations: previous_violations,
              danger_id: danger_id,
              template: "gitlab"
            )

            post_or_update_comment(comment_body, last_comment, should_create_new)
          end

          protected

          # Filters violations suitable for MR comment (non-inline).
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

          # Filters markdowns suitable for MR comment (non-inline).
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

          # Finds existing non-inline Danger comments.
          #
          # @return [Array<Comment>] Array of Danger-generated comments
          #
          def find_danger_comments
            context.mr_comments
              .select { |comment| comment.generated_by_danger?(danger_id) }
              .reject(&:inline?)
          end

          # Deletes old Danger comments.
          #
          # @return [void]
          #
          def delete_old_comments!
            context.delete_old_comments!(danger_id: danger_id)
          rescue StandardError => e
            log_warning("Failed to delete old comments: #{e.message}")
          end

          # Posts or updates the comment on the MR.
          #
          # @param comment_body [String] The comment body
          # @param last_comment [Comment, nil] Last existing comment
          # @param should_create_new [Boolean] Whether to create new comment
          # @return [void]
          #
          def post_or_update_comment(comment_body, last_comment, should_create_new)
            repo_slug = context.ci_source.repo_slug
            mr_id = context.ci_source.pull_request_id

            if should_create_new
              context.client.create_merge_request_note(repo_slug, mr_id, comment_body)
            else
              context.client.edit_merge_request_note(repo_slug, mr_id, last_comment.id, comment_body)
            end
          rescue StandardError => e
            log_warning("Failed to post comment: #{e.message}")
          end
        end
      end
    end
  end
end
