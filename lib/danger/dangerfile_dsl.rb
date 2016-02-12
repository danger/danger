module Danger
  class Dangerfile
    module DSL
      # @!group Enviroment
      # @return [EnvironmentManager] Provides access to the raw Travis/Circle/Buildkite/GitHub
      # objects, which you can use to pull out extra bits of information. _Warning_
      # the api of these objects is **not** considered a part of the Dangerfile public
      # API, and is viable to change occasionally on the whims of developers.

      attr_reader :env

      def initialize
        self.warnings = []
        self.errors = []
        self.messages = []
      end

      # Declares a CI blocking error
      #
      # @param    [String] message
      #           The message to present to the user
      def fail(message)
        self.errors << message
        puts "Raising error '#{message}'"
      end

      # Specifies a problem, but not critical
      #
      # @param    [String] message
      #           The message to present to the user
      def warn(message)
        self.warnings << message
        puts "Printing warning '#{message}'"
      end

      # Print out a generate message on the PR
      #
      # @param    [String] message
      #           The message to present to the user
      def message(message)
        self.messages << message
        puts "Printing message '#{message}'"
      end

      # When an undefined method is called, we check to see if it's something
      # that either the `scm` or the `request_source` can handle.
      # This opens us up to letting those object extend themselves naturally.
      def method_missing(method_sym, *_arguments, &_block)
        unless AvailableValues.all.include?(method_sym)
          raise "Unknown method '#{method_sym}', please check out the documentation for available variables".red
        end

        if AvailableValues.scm.include?(method_sym)
          # SCM Source
          return env.scm.send(method_sym)
        end

        if AvailableValues.request_source.include?(method_sym)
          # Request Source
          return env.request_source.send(method_sym)
        end
      end
    end
  end
end
