module Danger
  class Dangerfile
    class ExampleBroken # not a subclass < Plugin
      def run
        return "Hi there"
      end
    end
  end
end
