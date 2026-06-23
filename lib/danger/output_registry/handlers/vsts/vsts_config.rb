# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module VSTS
        # Configuration constants for VSTS (Azure DevOps) handlers.
        #
        module VSTSConfig
          # Header marker for Danger-generated comments
          PR_REVIEW_HEADER = "generated_by_danger"
        end
      end
    end
  end
end
