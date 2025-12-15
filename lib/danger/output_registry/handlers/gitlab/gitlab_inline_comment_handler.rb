# frozen_string_literal: true

require_relative "gitlab_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitLab
        # Posts inline comments on specific file lines in a GitLab MR.
        #
        # This handler posts violations as inline comments (discussions) on the MR,
        # matching violations to the specific file and line they reference.
        #
        # @example
        #   handler = GitLabInlineCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitLabInlineCommentHandler < OutputHandler
          # Executes the handler to post inline comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?
            return unless context.kind_of?(::Danger::RequestSources::GitLab)
            return unless supports_inline_comments?

            inline_violations = filter_inline_violations
            return if inline_violations.values.all?(&:empty?)

            post_inline_comments(inline_violations)
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

          # Posts inline comments to the MR.
          #
          # @param violations [Hash] Violations with file/line info
          # @return [void]
          #
          def post_inline_comments(violations)
            violations_list = violations[:errors] + violations[:warnings] + violations[:messages]

            violations_list.each do |violation|
              post_inline_comment(violation)
            rescue StandardError => e
              log_warning("Failed to post inline comment: #{e.message}")
            end
          end

          # Posts a single inline comment.
          #
          # @param violation [Violation] The violation to post
          # @return [void]
          #
          def post_inline_comment(violation)
            emoji = GitLabConfig::TYPE_MAPPINGS[violation.type][:emoji]
            body = generate_inline_body(emoji, violation)

            old_position = find_old_position(violation)
            return if old_position.nil?

            params = build_discussion_params(violation, old_position, body)
            context.client.create_merge_request_discussion(
              context.ci_source.repo_slug,
              context.ci_source.pull_request_id,
              params
            )
          end

          # Generates the body for an inline comment.
          #
          # @param emoji [String] The emoji identifier
          # @param violation [Violation] The violation
          # @return [String] The comment body
          #
          def generate_inline_body(emoji, violation)
            ":#{emoji}: #{violation.message}"
          end

          # Builds params for creating a discussion.
          #
          # @param violation [Violation] The violation
          # @param old_position [Hash] Old position info
          # @param body [String] Comment body
          # @return [Hash] Discussion parameters
          #
          def build_discussion_params(violation, old_position, body)
            mr_json = context.mr_json
            {
              body: body,
              position: {
                position_type: "text",
                new_path: violation.file,
                new_line: violation.line,
                old_path: old_position[:path],
                old_line: old_position[:line],
                base_sha: mr_json.diff_refs.base_sha,
                start_sha: mr_json.diff_refs.start_sha,
                head_sha: mr_json.diff_refs.head_sha
              }
            }
          end

          # Finds the old position in the diff for a violation.
          #
          # @param violation [Violation] The violation
          # @return [Hash, nil] Hash with :path and :line, or nil if not found
          #
          def find_old_position(violation)
            changes = context.mr_changes.changes
            change = changes.find { |c| c["new_path"] == violation.file }

            return nil if change.nil? || change["diff"].empty? || change["deleted_file"]

            modified_position = { path: change["old_path"], line: nil }
            return modified_position if change["new_file"]

            calculate_old_line(change, violation, modified_position)
          end

          # Calculates the old line number from diff.
          #
          # @param change [Hash] The change info
          # @param violation [Violation] The violation
          # @param modified_position [Hash] Position hash to update
          # @return [Hash] Updated position with line number
          #
          def calculate_old_line(change, violation, modified_position)
            range_header_regexp = /@@ -(?<old>[0-9]+)(?:,(?:[0-9]+))? \+(?<new>[0-9]+)(?:,(?:[0-9]+))? @@.*/

            current_old_line = 0
            current_new_line = 0

            change["diff"].each_line do |line|
              match = line.match(range_header_regexp)

              if match
                break if violation.line.to_i < match[:new].to_i

                current_old_line = match[:old].to_i - 1
                current_new_line = match[:new].to_i - 1
                next
              end

              if line.start_with?("-")
                current_old_line += 1
              elsif line.start_with?("+")
                current_new_line += 1
                return modified_position if current_new_line == violation.line.to_i
              elsif !line.eql?("\\ No newline at end of file\n")
                current_old_line += 1
                current_new_line += 1
                break if current_new_line == violation.line.to_i
              end
            end

            {
              path: change["old_path"],
              line: current_old_line - current_new_line + violation.line.to_i
            }
          end
        end
      end
    end
  end
end
