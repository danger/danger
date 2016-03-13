module Danger
  # Defines all the values that should be available in someone's Dangerfile
  class AvailableValues
    def self.all
      self.scm + self.request_source
    end

    def self.scm
      [
        :lines_of_code,
        :modified_files,
        :deleted_files,
        :added_files,
        :deletions,
        :insertions
      ]
    end

    def self.request_source
      [
        :pr_title,
        :pr_body,
        :pr_author,
        :pr_labels
      ]
    end
  end
end
