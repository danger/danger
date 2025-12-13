# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Configuration constants for GitHub output handlers.
        #
        # Centralizes all hardcoded configuration values, making them easier
        # to maintain and customize.
        #
        module GitHubConfig
          # Check Run Configuration
          CHECK_RUN_NAME = "Danger"
          CHECK_RUN_TITLE = "Danger Review"
          CHECK_RUN_NO_VIOLATIONS = "No violations found"
          MAX_ANNOTATIONS_PER_REQUEST = 50

          # Commit Status Configuration
          COMMIT_STATUS_CONTEXT = "danger/review"
          COMMIT_STATUS_MAX_LENGTH = 140

          # Comment Messages
          PR_REVIEW_HEADER = "Danger has reviewed this PR"
          ERRORS_SECTION_TITLE = "Errors"
          WARNINGS_SECTION_TITLE = "Warnings"
          MESSAGES_SECTION_TITLE = "Messages"

          # Violation Type Mappings (emoji + level for GitHub API)
          TYPE_MAPPINGS = {
            error: { emoji: "🚫", level: "failure" },
            warning: { emoji: "⚠️", level: "notice" },
            message: { emoji: "💬", level: "notice" }
          }.freeze

          # Status Configuration
          FAILURE_STATUS = "failure"
          SUCCESS_STATUS = "success"
          NEUTRAL_STATUS = "neutral"
        end
      end
    end
  end
end
