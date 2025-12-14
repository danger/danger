# frozen_string_literal: true

require_relative "github_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts GitHub Check Run with annotations for violations.
        #
        # This handler creates a GitHub Check Run with annotations for each violation,
        # providing inline feedback in the Files Changed tab of the PR.
        #
        # @example
        #   handler = GitHubCheckHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitHubCheckHandler < OutputHandler
          # Executes the handler to post GitHub Check Run.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?
            return unless github?

            create_check_run(github_request_source)
          end

          protected

          # Creates a GitHub Check Run with annotations.
          #
          # @param request_source [Danger::RequestSources::GitHub] The GitHub request source
          # @return [void]
          #
          def create_check_run(_request_source)
            metadata = github_pr_metadata
            return unless metadata

            annotations = build_annotations
            conclusion = errors.any? ? "failure" : "neutral"
            summary = build_summary

            annotations.each_slice(GitHubConfig::MAX_ANNOTATIONS_PER_REQUEST) do |batch|
              metadata[:client].create_check_run(
                metadata[:repo_slug],
                name: GitHubConfig::CHECK_RUN_NAME,
                head_sha: metadata[:commit_sha],
                status: "completed",
                conclusion: conclusion,
                completed_at: Time.now.utc.iso8601,
                output: {
                  title: GitHubConfig::CHECK_RUN_TITLE,
                  summary: summary,
                  annotations: batch
                }
              )
            end
          rescue StandardError => e
            log_warning("Failed to create check run: #{e.message}")
          end

          # Builds annotations for violations.
          #
          # @return [Array<Hash>] Array of annotation hashes
          #
          def build_annotations
            annotations = []

            all_violations.each do |violation|
              next unless violation.file && violation.line

              annotations << {
                path: violation.file,
                start_line: violation.line,
                end_line: violation.line,
                annotation_level: violation_type_mapping(violation.type, :annotation_level),
                message: violation.message,
                title: "Danger"
              }
            end

            annotations
          end

          # Builds a summary for the check run.
          #
          # @return [String] Summary text
          #
          def build_summary
            parts = []
            parts << "#{errors.count} error(s)" if errors.any?
            parts << "#{warnings.count} warning(s)" if warnings.any?
            parts << "#{messages.count} message(s)" if messages.any?

            if parts.empty?
              GitHubConfig::CHECK_RUN_NO_VIOLATIONS
            else
              "Found #{parts.join(', ')}"
            end
          end
        end
      end
    end
  end
end
