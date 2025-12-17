# frozen_string_literal: true

require_relative "gitlab_config"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

module Danger
  module OutputRegistry
    module Handlers
      module GitLab
        # Posts inline comments on specific file lines in a GitLab MR.
        #
        # This handler posts violations as inline comments (discussions) on the MR,
        # matching violations to the specific file and line they reference.
        # It manages comment lifecycle including creation, updates, and cleanup.
        #
        # @example
        #   handler = GitLabInlineCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitLabInlineCommentHandler < OutputHandler
          include Danger::Helpers::CommentsHelper

          # Executes the handler to post inline comments.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::GitLab)
            return unless supports_inline_comments?

            inline_violations = filter_inline_violations
            inline_markdowns = filter_inline_markdowns

            # Fetch existing danger inline comments
            @danger_comments = fetch_danger_inline_comments
            @non_danger_comments = fetch_non_danger_inline_comments

            # Process each violation type
            %i(error warning message).each do |type|
              process_violations_for_type(type, inline_violations[:"#{type}s"])
            end

            # Process inline markdowns
            process_inline_markdowns(inline_markdowns)

            # Clean up stale comments
            cleanup_stale_comments
          end

          protected

          # Checks if the GitLab instance supports inline comments.
          #
          # @return [Boolean]
          #
          def supports_inline_comments?
            context.supports_inline_comments
          end

          # Filters violations that have file and line information.
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_inline_violations
            filter_violations { |v| v.file && v.line }
          end

          # Filters markdowns that have file and line information.
          #
          # @return [Array] Array of inline markdowns
          #
          def filter_inline_markdowns
            markdowns.select { |m| m.file && m.line }
          end

          # Fetches existing danger inline comments from discussions.
          #
          # @return [Array<Hash>] Array of comment hashes with discussion_id
          #
          def fetch_danger_inline_comments
            all_inline_comments.select do |comment|
              Danger::Comment.from_gitlab(comment).generated_by_danger?(danger_id)
            end
          end

          # Fetches non-danger inline comments for reply detection.
          #
          # @return [Array<Hash>] Array of non-danger comment hashes
          #
          def fetch_non_danger_inline_comments
            all_inline_comments.reject do |comment|
              Danger::Comment.from_gitlab(comment).generated_by_danger?(danger_id)
            end
          end

          # Fetches all inline comments from MR discussions.
          #
          # @return [Array<Hash>] Array of comment hashes
          #
          def all_inline_comments
            @all_inline_comments ||= context.mr_discussions
              .auto_paginate
              .flat_map { |discussion| discussion.notes.map { |note| note.to_h.merge({ "discussion_id" => discussion.id }) } }
              .select { |comment| Danger::Comment.from_gitlab(comment).inline? }
          end

          # Processes violations of a specific type.
          #
          # @param type [Symbol] The violation type (:error, :warning, :message)
          # @param violations [Array] The violations to process
          # @return [void]
          #
          def process_violations_for_type(type, violations)
            violations.each do |violation|
              process_single_violation(type, violation)
            end
          end

          # Processes a single violation.
          #
          # @param type [Symbol] The violation type
          # @param violation [Violation] The violation
          # @return [void]
          #
          def process_single_violation(type, violation)
            # Check if should be dismissed (out of range + dismiss mode)
            if dismiss_out_of_range_for?(type) && out_of_range?(violation)
              return
            end

            emoji = GitLabConfig::TYPE_MAPPINGS[type][:emoji]
            processed = process_markdown(violation, true)
            body = generate_inline_comment_body(emoji, processed, danger_id: danger_id, template: "gitlab")

            # Find matching existing comment
            matching_comment = find_matching_comment(violation)

            if matching_comment
              # Update existing comment and remove from cleanup list
              @danger_comments.delete(matching_comment)
              update_comment(matching_comment, body)
            else
              # Try to create new inline comment
              # If it fails (out of range or API error), report to main comment
              unless create_inline_comment(violation, body)
                report_out_of_range_violation(:"#{type}s", violation)
              end
            end
          rescue StandardError => e
            log_warning("Failed to process inline comment for #{violation.file}:#{violation.line}: #{e.message}")
            # On error, report to main comment
            report_out_of_range_violation(:"#{type}s", violation)
          end

          # Processes inline markdowns.
          #
          # @param markdowns [Array] The markdowns to process
          # @return [void]
          #
          def process_inline_markdowns(markdowns)
            markdowns.each do |markdown|
              # Skip if dismissed (out of range + dismiss mode)
              next if dismiss_out_of_range_for?(:markdown) && out_of_range?(markdown)

              body = context.generate_inline_markdown_body(markdown, danger_id: danger_id, template: "gitlab")
              matching_comment = find_matching_comment(markdown)

              if matching_comment
                @danger_comments.delete(matching_comment)
                update_comment(matching_comment, body)
              else
                # Try to create inline comment, report to main if fails
                unless create_inline_comment(markdown, body)
                  report_out_of_range_markdown(markdown)
                end
              end
            rescue StandardError => e
              log_warning("Failed to process inline markdown: #{e.message}")
              report_out_of_range_markdown(markdown)
            end
          end

          # Checks if a violation/markdown is out of range in the diff.
          #
          # @param item [Violation, Markdown] The item to check
          # @return [Boolean] true if out of range
          #
          def out_of_range?(item)
            changes = context.mr_changes.changes
            change = changes.find { |c| c["new_path"] == item.file }

            # Out of range if no change, empty diff, or deleted file
            return true if change.nil? || change["diff"].empty? || change["deleted_file"]

            # New files are always in range
            return false if change["new_file"]

            # Check if line is in the diff range
            !line_in_diff?(change, item.line)
          end

          # Checks if a line is within the diff range.
          #
          # @param change [Hash] The change info
          # @param line [Integer] The line number
          # @return [Boolean] true if line is in diff
          #
          def line_in_diff?(change, line)
            range_header_regexp = /@@ -(?<old>[0-9]+)(?:,(?:[0-9]+))? \+(?<new>[0-9]+)(?:,(?<count>[0-9]+))? @@.*/

            change["diff"].each_line do |diff_line|
              match = diff_line.match(range_header_regexp)
              next unless match

              range_start = match[:new].to_i
              range_count = match[:count]&.to_i || 1
              range_end = range_start + range_count

              return true if line.to_i >= range_start && line.to_i < range_end
            end

            false
          end

          # Handles an out-of-range violation.
          #
          # @param type [Symbol] The violation type
          # @param violation [Violation] The violation
          # @return [void]
          #
          def handle_out_of_range_violation(type, violation)
            return if dismiss_out_of_range_for?(type)

            report_out_of_range_violation(:"#{type}s", violation)
          end

          # Checks if out-of-range items should be dismissed for a given type.
          #
          # @param type [Symbol] The type (:error, :warning, :message, :markdown)
          # @return [Boolean] true if should be dismissed
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

          # Finds a matching existing comment for a violation/markdown.
          #
          # @param item [Violation, Markdown] The item to match
          # @return [Hash, nil] The matching comment or nil
          #
          def find_matching_comment(item)
            @danger_comments.find do |comment|
              position = comment["position"]
              next false if position.nil?

              position["new_path"] == item.file && position["new_line"] == item.line
            end
          end

          # Updates an existing comment.
          #
          # @param comment [Hash] The comment to update
          # @param body [String] The new body
          # @return [void]
          #
          def update_comment(comment, body)
            context.client.update_merge_request_discussion_note(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              comment["discussion_id"],
              comment["id"],
              body: body
            )
          rescue StandardError => e
            log_warning("Failed to update inline comment: #{e.message}")
          end

          # Creates a new inline comment.
          #
          # @param item [Violation, Markdown] The item to comment on
          # @param body [String] The comment body
          # @return [Boolean] true if comment was created successfully
          #
          def create_inline_comment(item, body)
            old_position = find_old_position(item)
            return false if old_position.nil?

            params = build_discussion_params(item, old_position, body)
            context.client.create_merge_request_discussion(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              params
            )
            true
          rescue StandardError => e
            log_warning("Failed to create inline comment (#{item.file}:#{item.line}): #{e.message}")
            false
          end

          # Builds params for creating a discussion.
          #
          # @param item [Violation, Markdown] The item
          # @param old_position [Hash] Old position info
          # @param body [String] Comment body
          # @return [Hash] Discussion parameters
          #
          def build_discussion_params(item, old_position, body)
            mr_json = context.mr_json
            {
              body: body,
              position: {
                position_type: "text",
                new_path: item.file,
                new_line: item.line,
                old_path: old_position[:path],
                old_line: old_position[:line],
                base_sha: mr_json.diff_refs.base_sha,
                start_sha: mr_json.diff_refs.start_sha,
                head_sha: mr_json.diff_refs.head_sha
              }
            }
          end

          # Finds the old position in the diff for an item.
          #
          # @param item [Violation, Markdown] The item
          # @return [Hash, nil] Hash with :path and :line, or nil if not found
          #
          def find_old_position(item)
            changes = context.mr_changes.changes
            change = changes.find { |c| c["new_path"] == item.file }

            return nil if change.nil? || change["diff"].empty? || change["deleted_file"]

            modified_position = { path: change["old_path"], line: nil }
            return modified_position if change["new_file"]

            calculate_old_line(change, item, modified_position)
          end

          # Calculates the old line number from diff.
          #
          # @param change [Hash] The change info
          # @param item [Violation, Markdown] The item
          # @param modified_position [Hash] Position hash to update
          # @return [Hash] Updated position with line number
          #
          def calculate_old_line(change, item, modified_position)
            range_header_regexp = /@@ -(?<old>[0-9]+)(?:,(?:[0-9]+))? \+(?<new>[0-9]+)(?:,(?:[0-9]+))? @@.*/

            current_old_line = 0
            current_new_line = 0

            change["diff"].each_line do |line|
              match = line.match(range_header_regexp)

              if match
                break if item.line.to_i < match[:new].to_i

                current_old_line = match[:old].to_i - 1
                current_new_line = match[:new].to_i - 1
                next
              end

              if line.start_with?("-")
                current_old_line += 1
              elsif line.start_with?("+")
                current_new_line += 1
                return modified_position if current_new_line == item.line.to_i
              elsif !line.eql?("\\ No newline at end of file\n")
                current_old_line += 1
                current_new_line += 1
                break if current_new_line == item.line.to_i
              end
            end

            {
              path: change["old_path"],
              line: current_old_line - current_new_line + item.line.to_i
            }
          end

          # Cleans up stale inline comments.
          #
          # @return [void]
          #
          def cleanup_stale_comments
            @danger_comments.each do |comment|
              cleanup_single_comment(comment)
            end
          end

          # Cleans up a single stale comment.
          #
          # @param comment [Hash] The comment to clean up
          # @return [void]
          #
          def cleanup_single_comment(comment)
            violation = violations_from_table(comment["body"]).first

            if violation&.sticky
              # Cross out sticky violations
              body = generate_inline_comment_body(
                "white_check_mark",
                violation,
                danger_id: danger_id,
                resolved: true,
                template: "gitlab"
              )
              update_comment(comment, body)
            else
              # Delete non-sticky violations if no replies
              delete_comment_if_no_replies(comment)
            end
          rescue StandardError => e
            log_warning("Failed to cleanup inline comment: #{e.message}")
          end

          # Deletes a comment if it has no replies.
          #
          # @param comment [Hash] The comment to potentially delete
          # @return [void]
          #
          def delete_comment_if_no_replies(comment)
            replies = @non_danger_comments.select do |potential|
              potential["position"] == comment["position"]
            end

            return unless replies.empty?

            context.client.delete_merge_request_comment(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              comment["id"]
            )
          end
        end
      end
    end
  end
end
