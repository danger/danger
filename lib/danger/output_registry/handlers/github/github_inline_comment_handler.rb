# frozen_string_literal: true

require_relative "github_config"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

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
            return unless context.kind_of?(::Danger::RequestSources::GitHub)

            inline_violations = filter_inline_violations
            inline_markdowns = filter_inline_markdowns
            return if inline_violations.values.all?(&:empty?) && inline_markdowns.empty?

            post_inline_comments(inline_violations, inline_markdowns)
          end

          protected

          # Filters violations that have file and line information.
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_inline_violations
            filter_violations { |v| v.file && v.line }.tap do |filtered|
              %i(warnings errors messages).each { |key| filtered[key] ||= [] }
            end
          end

          # Filters markdowns that have file and line information.
          #
          # @return [Array] Markdowns that can be posted inline
          #
          def filter_inline_markdowns
            markdowns.select { |m| m.file && m.line }
          end

          # Posts inline comments to the PR.
          #
          # @param violations [Hash] Violations with file/line info
          # @param inline_markdowns [Array] Markdowns with file/line info
          # @return [void]
          #
          def post_inline_comments(violations, inline_markdowns = [])
            # Get existing PR comments and filter for danger comments
            pr_comments = context.client.pull_request_comments(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id
            )
            danger_comments = pr_comments.select do |comment|
              Danger::Comment.from_github(comment).generated_by_danger?(danger_id)
            end
            non_danger_comments = pr_comments - danger_comments

            # Get diff lines for position calculation
            diff_lines = context.pr_diff.lines

            %i(error warning message).each do |type|
              emoji = GitHubConfig::TYPE_MAPPINGS[type][:emoji]
              violations[:"#{type}s"].each do |violation|
                post_single_inline_comment(violation, emoji, diff_lines, danger_comments, type)
              end
            end

            inline_markdowns.each do |markdown|
              post_single_inline_comment(markdown, nil, diff_lines, danger_comments, :markdown)
            end

            # Clean up old inline comments that are no longer valid
            cleanup_old_inline_comments(danger_comments, non_danger_comments)
          end

          # Posts a single inline comment.
          #
          # @param violation [Violation] The violation to post
          # @param emoji [String, nil] Emoji to display (nil for markdowns)
          # @param diff_lines [Array<String>] Lines from the PR diff
          # @param danger_comments [Array] Existing danger comments (modified in place)
          # @param type [Symbol] The violation type (:error, :warning, :message, :markdown)
          # @return [void]
          #
          def post_single_inline_comment(violation, emoji, diff_lines, danger_comments, type)
            position = find_position_in_diff(diff_lines, violation, type)

            # A ranged comment also needs its start line inside the diff
            if position.nil? || start_position_out_of_range?(diff_lines, violation, type)
              # Check if we should dismiss it or report it to the comment handler
              unless dismiss_out_of_range_for?(type)
                if type == :markdown
                  report_out_of_range_markdown(violation)
                else
                  report_out_of_range_violation(:"#{type}s", violation)
                end
              end
              return
            end

            # Generate comment body using Danger's template
            if type == :markdown
              body = generate_inline_markdown_body(violation, danger_id: danger_id, template: "github")
            else
              violation = process_markdown(violation, true)
              body = generate_inline_comment_body(emoji, violation, danger_id: danger_id, template: "github")
            end

            # Check for existing matching comment
            matching_comment = find_matching_comment(danger_comments, violation, position, body)

            if matching_comment
              # Comment exists, update if needed and remove from cleanup list
              danger_comments.delete(matching_comment)
              update_inline_comment(matching_comment, body)
            else
              # Create new inline comment
              create_inline_comment(violation, body, position)
            end
          rescue StandardError => e
            log_warning("Failed to post inline comment for #{violation.file}:#{violation.line}: #{e.message}")
          end

          # @return [Boolean] true if a ranged message starts on a line outside the diff
          def start_position_out_of_range?(diff_lines, violation, type)
            return false unless ranged?(violation)

            start_reference = ::Danger::RequestSources::GitHub::DiffLineReference.new(violation.file, violation.start_line)
            find_position_in_diff(diff_lines, start_reference, type).nil?
          end

          def ranged?(violation)
            !violation.start_line.nil?
          end

          # Finds the position in the diff for a violation.
          #
          # @param diff_lines [Array<String>] Lines from the PR diff
          # @param violation [Violation] The violation
          # @param type [Symbol] The violation type; in dismiss mode only added lines count as in range
          # @return [Integer, nil] The position, or nil if not found
          #
          def find_position_in_diff(diff_lines, violation, type)
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
                if file_line == violation.line
                  file_line = nil if dismiss_out_of_range_for?(type) && !line.start_with?("+")
                  break
                end

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
              next false unless comment["path"] == violation.file
              next false unless ranged?(violation) ? ranged_lines_match?(comment, violation) : comment["position"] == position

              # Compare body without blob hashes (they change between commits)
              comment["body"].sub(blob_regexp, "") == body.sub(blob_regexp, "")
            end
          end

          def ranged_lines_match?(comment, violation)
            return false if comment["line"].nil? || comment["start_line"].nil?

            comment["line"].to_i == violation.line && comment["start_line"].to_i == violation.start_line
          end

          # Rewrites an existing inline comment, which also removes any strikethrough
          # left from a previous run (matches the pre-registry behavior).
          #
          # @param comment [Hash] The existing comment
          # @param body [String] The new body
          # @return [void]
          #
          def update_inline_comment(comment, body)
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
            # Octokit v7 only supports diff positions, so ranged metadata is ignored there.
            range_options = if ranged?(violation) && Octokit::MAJOR >= 8
                              {
                                start_line: violation.start_line,
                                side: violation.side || "RIGHT",
                                start_side: violation.start_side || "RIGHT"
                              }
                            else
                              {}
                            end

            context.client.create_pull_request_comment(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              body,
              head_ref,
              violation.file,
              line_arg,
              **range_options
            )
          rescue Octokit::UnprocessableEntity => e
            log_warning("Failed to create inline comment (#{violation.file}:#{violation.line}): #{e.message}")
          end

          # Cleans up old inline comments that are no longer valid.
          #
          # @param remaining_comments [Array] Comments that weren't matched to current violations
          # @param non_danger_comments [Array] Human comments, used to detect replies
          # @return [void]
          #
          def cleanup_old_inline_comments(remaining_comments, non_danger_comments = [])
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
                # Keep comments that have replies; GitHub has no reply concept here, so any
                # human comment on the same line of the same commit counts as one
                replies = non_danger_comments.select do |other|
                  other["path"] == comment["path"] &&
                    other["position"] == comment["position"] &&
                    other["commit_id"] == comment["commit_id"]
                end

                if replies.empty?
                  context.client.delete_pull_request_comment(
                    context.ci_source.repo_slug,
                    comment["id"]
                  )
                end
              end
            rescue StandardError => e
              log_warning("Failed to cleanup inline comment: #{e.message}")
            end
          end

          # Checks if out-of-range violations should be dismissed for a given type.
          #
          # @param type [Symbol] The violation type (:error, :warning, :message)
          # @return [Boolean] true if out-of-range violations should be dismissed
          #
          def dismiss_out_of_range_for?(type)
            dismiss_setting = context.dismiss_out_of_range_messages
            return false unless dismiss_setting

            if dismiss_setting.kind_of?(Hash)
              dismiss_setting[type]
            else
              dismiss_setting == true
            end
          end
        end
      end
    end
  end
end
