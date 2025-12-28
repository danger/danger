# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module BitbucketServer
        # Configuration constants for Bitbucket Server handlers.
        #
        module BitbucketServerConfig
          # Header marker for Danger-generated comments
          PR_REVIEW_HEADER = "generated_by_danger"

          # Section titles for different violation types
          ERRORS_SECTION_TITLE = "Errors"
          WARNINGS_SECTION_TITLE = "Warnings"
          MESSAGES_SECTION_TITLE = "Messages"
        end
      end
    end
  end
end
