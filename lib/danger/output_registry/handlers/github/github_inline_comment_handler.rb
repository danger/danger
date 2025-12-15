# frozen_string_literal: true

require_relative "github_config"
require "danger/helpers/comments_helper"

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts inline comments on specific file lines in a GitHub PR.
        #
        # This handler posts violations as inline comments on the PR,
        # matching violations to the specific file and line they reference.
        # Only violations within the PR diff can be posted as inline comments.
        #
        # @example
        #   handler = GitHubInlineCommentHandler.new(context, violations, danger_id: "my-danger")
        #   handler.execute if handler.enabled?
        #
        class GitHubInlineCommentHandler < OutputHandler
          include Danger::Helpers::CommentsHelper

          # Executes the handler to post inline comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?
            return unless context.kind_of?(::Danger::RequestSources::GitHub)

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
            # Get existing PR comments and filter for danger comments
            pr_comments = context.client.pull_request_comments(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id
            )
            danger_comments = pr_comments.select do |comment|
              Danger::Helpers::Comment.from_github(comment).generated_by_danger?(danger_id)
            end

            # Get diff lines for position calculation
            diff_lines = context.pr_diff.lines

            %i(error warning message).each do |type|
              emoji = GitHubConfig::TYPE_MAPPINGS[type][:emoji]
              violations[:"#{type}s"].each do |violation|
                post_single_inline_comment(violation, emoji, diff_lines, danger_comments)
              end
            end

            # Clean up old inline comments that are no longer valid
            cleanup_old_inline_comments(danger_comments)
          end

          # Posts a single inline comment.
          #
          # @param violation [Violation] The violation to post
          # @param emoji [String] Emoji to display
          # @param diff_lines [Array<String>] Lines from the PR diff
          # @param danger_comments [Array] Existing danger comments (modified in place)
          # @return [void]
          #
          def post_single_inline_comment(violation, emoji, diff_lines, danger_comments)
            position = find_position_in_diff(diff_lines, violation)
            return unless position

            # Generate comment body using Danger's template
            processed_violation = process_markdown(violation, true)
            body = generate_inline_comment_body(emoji, processed_violation, danger_id: danger_id, template: "github")

            # Check for existing matching comment
            matching_comment = find_matching_comment(danger_comments, violation, position, body)

            if matching_comment
              # Comment exists, update if needed and remove from cleanup list
              danger_comments.delete(matching_comment)
              update_inline_comment_if_needed(matching_comment, body)
            else
              # Create new inline comment
              create_inline_comment(violation, body, position)
            end
          rescue StandardError => e
            log_warning("Failed to post inline comment for #{violation.file}:#{violation.line}: #{e.message}")
          end

          # Finds the position in the diff for a violation.
          #
          # @param diff_lines [Array<String>] Lines from the PR diff
          # @param violation [Violation] The violation
          # @return [Integer, nil] The position, or nil if not found
          #
          def find_position_in_diff(diff_lines, violation)
            range_header_regexp = /@@ -\d+(?:,\d+)? \+(?<start>\d+)(?:,(?<end>\d+))? @@.*/
            file_header_regexp = %r{^diff --git a/.*}

            pattern = "+++ b/#{violation.file}\n"
            file_start = diff_lines.index(pattern)

            # Try with trailing tab (for files with spaces)
            if file_start.nil?
              pattern = "+++ b/#{violation.file}\t\n"
              file_start = diff_lines.index(pattern)
            end

            return nil if file_start.nil?

            position = -1
            file_line = nil

            diff_lines.drop(file_start).each do |line|
              break if line.match?(file_header_regexp)

              if line.eql?("\\ No newline at end of file\n")
                position += 1
                next
              end

              match = line.match(range_header_regexp)

              if !file_line.nil? && !line.start_with?("-")
                break if file_line == violation.line

                file_line += 1
              end

              position += 1

              next unless match

              range_start = match[:start].to_i
              range_end = match[:end] ? match[:end].to_i + range_start : range_start

              break if violation.line.to_i < range_start
              next unless violation.line.to_i >= range_start && violation.line.to_i < range_end

              file_line = range_start
            end

            position unless file_line.nil?
          end

          # Finds a matching existing comment.
          #
          # @param danger_comments [Array] Existing danger comments
          # @param violation [Violation] The violation
          # @param position [Integer] The diff position
          # @param body [String] The expected comment body
          # @return [Hash, nil] The matching comment or nil
          #
          def find_matching_comment(danger_comments, violation, position, body)
            blob_regexp = %r{blob/[0-9a-z]+/}

            danger_comments.find do |comment|
              next false unless comment["path"] == violation.file && comment["position"] == position

              # Compare body without blob hashes (they change between commits)
              comment["body"].sub(blob_regexp, "") == body.sub(blob_regexp, "")
            end
          end

          # Updates an inline comment if the body has changed.
          #
          # @param comment [Hash] The existing comment
          # @param body [String] The new body
          # @return [void]
          #
          def update_inline_comment_if_needed(comment, body)
            return if comment["body"] == body

            context.client.update_pull_request_comment(
              context.ci_source.repo_slug,
              comment["id"],
              body
            )
          rescue StandardError => e
            log_warning("Failed to update inline comment: #{e.message}")
          end

          # Creates a new inline comment.
          #
          # @param violation [Violation] The violation
          # @param body [String] The comment body
          # @param position [Integer] The diff position
          # @return [void]
          #
          def create_inline_comment(violation, body, position)
            head_ref = context.pr_json["head"]["sha"]

            # Since Octokit v8, the signature changed - use line number directly
            line_arg = Octokit::MAJOR >= 8 ? violation.line : position

            context.client.create_pull_request_comment(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              body,
              head_ref,
              violation.file,
              line_arg
            )
          rescue Octokit::UnprocessableEntity => e
            log_warning("Failed to create inline comment (#{violation.file}:#{violation.line}): #{e.message}")
          end

          # Cleans up old inline comments that are no longer valid.
          #
          # @param remaining_comments [Array] Comments that weren't matched to current violations
          # @return [void]
          #
          def cleanup_old_inline_comments(remaining_comments)
            remaining_comments.each do |comment|
              # Check if it's a sticky violation
              violation = violations_from_table(comment["body"]).first
              if violation&.sticky
                # Mark as resolved but keep
                body = generate_inline_comment_body("white_check_mark", violation, danger_id: danger_id, resolved: true, template: "github")
                context.client.update_pull_request_comment(
                  context.ci_source.repo_slug,
                  comment["id"],
                  body
                )
              else
                # Delete non-sticky old comments
                context.client.delete_pull_request_comment(
                  context.ci_source.repo_slug,
                  comment["id"]
                )
              end
            rescue StandardError => e
              log_warning("Failed to cleanup inline comment: #{e.message}")
            end
          end
        end
      end
    end
  end
end
