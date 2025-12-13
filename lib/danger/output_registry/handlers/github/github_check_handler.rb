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

            # Create check run with annotations
            create_check_run(github_request_source)
          end

          protected

          # Creates a GitHub Check Run with annotations.
          #
          # @param request_source [Danger::RequestSources::GitHub] The GitHub request source
          # @return [void]
          #
          def create_check_run(request_source)
            client = request_source.client
            repo_slug = request_source.repo_slug
            commit_sha = request_source.pr_json["head"]["sha"]

            # Build annotations
            annotations = build_annotations

            # Determine overall conclusion
            conclusion = errors.any? ? "failure" : "neutral"
            summary = build_summary

            # Create check run (GitHub limits to 50 annotations per request)
            annotations.each_slice(GitHubConfig::MAX_ANNOTATIONS_PER_REQUEST) do |batch|
              client.create_check_run(
                repo_slug,
                name: GitHubConfig::CHECK_RUN_NAME,
                head_sha: commit_sha,
                conclusion: conclusion,
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
            all_violations = [errors, warnings, messages].flatten.compact
            annotations = []

            all_violations.each do |violation|
              next unless violation.file && violation.line

              annotations << {
                path: violation.file,
                start_line: violation.line,
                end_line: violation.line,
                annotation_level: annotation_level(violation.type),
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

          # Determines annotation level for violation type.
          #
          # @param type [Symbol] Violation type
          # @return [String] Annotation level: "failure", "warning", or "notice"
          #
          def annotation_level(type)
            case type
            when :error then "failure"
            when :warning then "warning"
            else "notice"
            end
          end
        end
      end
    end
  end
end
