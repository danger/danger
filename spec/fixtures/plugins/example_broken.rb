module Danger
  class Dangerfile
    module DSL
      class ExampleBroken # not a subclass < Plugin
        def run
          return "Hi there"
        end
      end
    end
  end
end
