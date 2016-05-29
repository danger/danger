module Danger
  class Dangerfile
    module DSL
      class ExampleRemote < Plugin
        def echo
          return "Hi there remote 🎉"
        end
      end
    end
  end
end
