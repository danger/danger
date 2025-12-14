# frozen_string_literal: true

require_relative "github_config"

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
          def post_inline_comments(_request_source, violations)
            metadata = github_pr_metadata
            return unless metadata

            violations_list = violations[:errors] + violations[:warnings] + violations[:messages]

            # Fetch PR diff to map line numbers to diff positions
            diff_map = fetch_diff_position_map(metadata)
            return unless diff_map

            violations_list.each do |violation|
              body = "#{violation.message} (#{violation_type_emoji(violation.type)})"
              position = diff_map[violation.file]&.[](violation.line)

              next unless position

              metadata[:client].create_pull_request_review_comment(
                metadata[:repo_slug],
                metadata[:pr_number],
                body,
                metadata[:commit_sha],
                violation.file,
                position
              )
            rescue StandardError => e
              # Log but continue with other violations
              log_warning("Failed to post inline comment: #{e.message}")
            end
          end

          # Fetches PR diff and builds a map of file/line -> diff position.
          #
          # GitHub Reviews API requires diff position (the line position within the diff),
          # not the raw file line number. This method fetches the PR diff and calculates
          # the correct position for each changed line.
          #
          # @param metadata [Hash] GitHub PR metadata
          # @return [Hash<String, Hash<Integer, Integer>>] Map of file => { line => position }
          # @return [nil] if diff cannot be fetched
          #
          def fetch_diff_position_map(metadata)
            diff_map = {}

            begin
              # Fetch the PR diff
              diff_response = metadata[:client].pull_request_files(
                metadata[:repo_slug],
                metadata[:pr_number]
              )

              diff_response.each do |file_info|
                file_path = file_info.filename
                diff_map[file_path] = {}

                # Parse the patch to map line numbers to diff positions
                next unless file_info.patch

                position = 0
                line_number = 0

                file_info.patch.each_line do |line|
                  position += 1

                  # Track actual line numbers from the patch
                  if line.start_with?("+") && !line.start_with?("+++")
                    line_number += 1
                    diff_map[file_path][line_number] = position
                  elsif !line.start_with?("-") && !line.start_with?("\\")
                    line_number += 1
                    diff_map[file_path][line_number] = position
                  end
                end
              end

              diff_map
            rescue StandardError => e
              log_warning("Failed to fetch PR diff for position mapping: #{e.message}")
              nil
            end
          end

          # Determines the emoji for a violation type.
          #
          # @param type [Symbol] Violation type (:error, :warning, :message)
          # @return [String] Emoji representation
          #
          def violation_type_emoji(type)
            mapping = GitHubConfig::TYPE_MAPPINGS[type] || GitHubConfig::TYPE_MAPPINGS[:message]
            mapping[:emoji]
          end
        end
      end
    end
  end
end
