module Danger
  class Dangerfile
    module DSL
      class ExampleGlobbing < Plugin
        def echo
          return "Hi there globbing"
        end
      end
    end
  end
end
