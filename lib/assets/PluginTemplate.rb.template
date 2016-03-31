module Danger
  class Dangerfile
    module DSL
      class [[CLASS_NAME]] < Plugin
        def run(parameter1: nil, parameter2: nil)
          if (pr_body + pr_title).include?("WIP")
            warn "Pull Request is Work in Progress"
          end
        end

        def self.description
          [
            "Describe what this plugin does",
            "and how the user can use it"
          ].join(" ")
        end
      end
    end
  end
end
