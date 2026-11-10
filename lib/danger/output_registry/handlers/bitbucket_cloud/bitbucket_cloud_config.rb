# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketCloud
        # Configuration constants for Bitbucket Cloud handlers.
        #
        module BitbucketCloudConfig
          # Header used to identify Danger-generated comments
          PR_REVIEW_HEADER = "<!-- generated_by_danger -->"

          # Section titles
          ERRORS_SECTION_TITLE = "Errors"
          WARNINGS_SECTION_TITLE = "Warnings"
          MESSAGES_SECTION_TITLE = "Messages"

          # Type mappings for violations
          TYPE_MAPPINGS = {
            error: { emoji: "no_entry_sign", level: "error" },
            warning: { emoji: "warning", level: "warning" },
            message: { emoji: "book", level: "notice" }
          }.freeze
        end
      end
    end
  end
end
