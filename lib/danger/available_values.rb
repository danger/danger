module Danger
  # Defines all the values that should be available in someone's Dangerfile
  class AvailableValues
    def self.all
      self.scm + self.request_source
    end

    def self.scm
      [
        :lines_of_code,
        :files_modified,
        :files_removed,
        :files_added,
        :deletions,
        :insertions
      ]
    end

    def self.request_source
      [
        :pr_title,
        :pr_body,
        :pr_author
      ]
    end
  end
end
