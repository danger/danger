module Danger
  class Dangerfile
    module DSL
      class ExampleExactPath < Plugin
        def run
          return "Hi there exact 🎉"
        end

        def self.description
          "Add a warning to PRs with 'WIP' in their title or body"
        end
      end
    end
  end
end
