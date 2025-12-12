# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts commit status to GitHub based on violations.
        #
        # This handler sets the commit status (success/failure) on the PR HEAD
        # based on whether there are any errors in the violations.
        #
        # @example
        #   handler = GitHubCommitStatusHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitHubCommitStatusHandler < OutputHandler
          # Executes the handler to post commit status.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?

            request_source = context.env.request_source
            return unless request_source.kind_of?(::Danger::RequestSources::GitHub)

            # Determine status based on violations
            status = errors.any? ? "failure" : "success"
            description = generate_status_description

            post_commit_status(request_source, status, description)
          end

          protected

          # Generates a description for the commit status.
          #
          # @return [String] Status description
          #
          def generate_status_description
            error_count = errors.count
            warning_count = warnings.count

            parts = []
            parts << "#{error_count} error#{'s' if error_count != 1}" if error_count.positive?
            parts << "#{warning_count} warning#{'s' if warning_count != 1}" if warning_count.positive?

            if parts.empty?
              "All checks passed"
            else
              "Danger: #{parts.join(', ')}"
            end
          end

          # Posts the commit status to GitHub.
          #
          # @param request_source [Danger::RequestSources::GitHub] The GitHub request source
          # @param status [String] Status: "success" or "failure"
          # @param description [String] Status description
          # @return [void]
          #
          def post_commit_status(request_source, status, description)
            client = request_source.client
            commit_sha = request_source.pr_json["head"]["sha"]
            repo_slug = request_source.repo_slug

            client.create_status(
              repo_slug,
              commit_sha,
              status,
              context: "danger/review",
              description: description.truncate(140)
            )
          rescue Octokit::Unauthorized => e
            warn("Unable to post commit status: #{e.message}")
          rescue StandardError => e
            raise "Failed to post commit status: #{e.message}"
          end
        end
      end
    end
  end
end
