module Danger
  class Dangerfile
    module DSL
      def work_in_progress_warning
        if (pr_body + pr_title).include?("WIP")
          warn "Pull Request is Work in Progress"
        end
      end
    end
  end
end
