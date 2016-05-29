module Danger
  class Dangerfile
    module DSL
      class ExampleExactPath < Plugin
        def echo
          return "Hi there exact"
        end
      end
    end
  end
end
