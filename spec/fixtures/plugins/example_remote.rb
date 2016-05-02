module Danger
  class Dangerfile
    module DSL
      class ExampleRemote < Plugin
        def run
          return "Hi there remote 🎉"
        end

        def self.description
          "Add a warning to PRs with 'WIP' in their title or body"
        end
      end
    end
  end
end
