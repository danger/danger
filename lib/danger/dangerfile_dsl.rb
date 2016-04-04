require 'danger/violation'

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
        self.markdown = []
        load_plugins
      end

      def load_plugins
        Dir['./lib/danger/plugins/*.rb'].each do |file|
          require file
        end
      end

      def should_ignore_violation(message)
        env.request_source.ignored_violations.include? message
      end

      # Declares a CI blocking error
      #
      # @param    [String] message
      #           The message to present to the user
      # @param    [Boolean] sticky
      #           Whether the message should be kept after it was fixed
      def fail(message, sticky: true)
        return if should_ignore_violation(message)
        self.errors << Violation.new(message, sticky)
        puts "Raising error '#{message}'"
      end

      # Specifies a problem, but not critical
      #
      # @param    [String] message
      #           The message to present to the user
      # @param    [Boolean] sticky
      #           Whether the message should be kept after it was fixed
      def warn(message, sticky: true)
        return if should_ignore_violation(message)
        self.warnings << Violation.new(message, sticky)
        puts "Printing warning '#{message}'"
      end

      # Print out a generate message on the PR
      #
      # @param    [String] message
      #           The message to present to the user
      # @param    [Boolean] sticky
      #           Whether the message should be kept after it was fixed
      def message(message, sticky: true)
        self.messages << Violation.new(message, sticky)
        puts "Printing message '#{message}'"
      end

      # Print markdown to below the table
      #
      # @param    [String] message
      #           The markdown based message to be printed below the table
      def markdown(message)
        self.markdown << message
        puts "Printing markdown #{message}"
      end

      # When an undefined method is called, we check to see if it's something
      # that either the `scm` or the `request_source` can handle.
      # This opens us up to letting those object extend themselves naturally.
      def method_missing(method_sym, *_arguments, &_block)
        if AvailableValues.scm.include?(method_sym)
          # SCM Source
          return env.scm.send(method_sym)
        end

        if AvailableValues.request_source.include?(method_sym)
          # Request Source
          return env.request_source.send(method_sym)
        end

        raise "Unknown method '#{method_sym}', please check out the documentation for available variables".red
      end
    end
  end
end
