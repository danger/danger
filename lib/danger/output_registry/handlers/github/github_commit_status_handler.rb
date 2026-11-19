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
        # Supports the following options:
        # - danger_id: Used in the status context (e.g., "danger/my-danger")
        #
        # @example
        #   handler = GitHubCommitStatusHandler.new(context, violations, danger_id: "my-danger")
        #   handler.execute if handler.enabled?
        #
        class GitHubCommitStatusHandler < OutputHandler
          # Executes the handler to post commit status.
          #
          # Delegates to the request source, which also aborts the build when an
          # errored run can't set its status.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::GitHub)

            context.submit_pull_request_status!(
              warnings: warnings, errors: errors, details_url: shared_state[:comment_url], danger_id: danger_id
            )
          end
        end
      end
    end
  end
end
