module Danger
  class Dangerfile
    module DSL
      class Plugin
        def initialize(dsl)
          @dsl = dsl
        end

        # Since we have a reference to the DSL containing all the information
        # We need to redirect the self calls to the DSL
        def method_missing(method_sym, *arguments, &_block)
          return @dsl.send(method_sym, *arguments) if @dsl.respond_to?(method_sym)
          return @dsl.method_missing(method_sym, *arguments)
        end
      end
    end
  end
end
