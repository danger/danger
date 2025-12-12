# frozen_string_literal: true

module Danger
  module OutputRegistry
    # Base class for all output handlers in the Output Registry system.
    #
    # OutputHandler provides the abstract interface that all concrete handlers
    # must implement. It follows the Template Method pattern, where the base
    # class defines the execution structure and subclasses provide specific
    # implementation details.
    #
    # @abstract Subclasses must implement {#execute} to provide handler-specific
    #   output behavior.
    #
    # @example Creating a custom handler
    #   class MyCustomHandler < OutputHandler
    #     def enabled?
    #       # Only run if we have warnings
    #       warnings.any?
    #     end
    #
    #     def execute
    #       puts "Found #{warnings.count} warnings"
    #       warnings.each { |w| puts "  - #{w}" }
    #     end
    #   end
    #
    # @example Using a handler
    #   violations = {
    #     warnings: ["Style issue"],
    #     errors: [],
    #     messages: []
    #   }
    #   MyCustomHandler.execute(danger_context, violations)
    #
    class OutputHandler
      # Executes the handler if it is enabled.
      #
      # This is the main entry point for running a handler. It instantiates
      # the handler with the provided context and violations, checks if it
      # should run via {#enabled?}, and executes it if so.
      #
      # @param context [Danger::DangerfileContext] The Danger context providing
      #   access to the environment, git information, and platform APIs
      # @param violations [Hash] Hash containing arrays of violations:
      #   - :warnings [Array<String>] Warning messages
      #   - :errors [Array<String>] Error messages
      #   - :messages [Array<String>] Info messages
      #
      # @return [void]
      #
      # @example Execute a handler
      #   MyHandler.execute(danger, { warnings: ["issue"], errors: [], messages: [] })
      #
      def self.execute(context, violations)
        handler = new(context, violations)
        handler.execute if handler.enabled?
      end

      # Initializes a new handler instance.
      #
      # @param context [Danger::DangerfileContext] The Danger context
      # @param violations [Hash] Hash containing violation arrays
      #
      def initialize(context, violations)
        @context = context
        @violations = violations
      end

      # Determines whether this handler should execute.
      #
      # The default implementation returns true, meaning the handler always
      # runs. Subclasses can override this to add conditional logic based on
      # environment variables, platform detection, violation presence, etc.
      #
      # @return [Boolean] true if handler should execute, false otherwise
      #
      # @example Override to run only on CI
      #   def enabled?
      #     ENV["CI"] == "true"
      #   end
      #
      def enabled?
        true
      end

      # Performs the handler's output operation.
      #
      # @abstract Subclasses must implement this method to provide specific
      #   output behavior (e.g., posting to GitHub, writing to file, etc.)
      #
      # @return [void]
      #
      # @raise [NotImplementedError] if not implemented by subclass
      #
      def execute
        raise NotImplementedError, "#{self.class.name} must implement #execute"
      end

      protected

      # @!attribute [r] context
      #   @return [Danger::DangerfileContext] The Danger context
      attr_reader :context

      # @!attribute [r] violations
      #   @return [Hash] The violations hash
      attr_reader :violations

      # Returns the array of warning messages.
      #
      # @return [Array<String>] Warning messages, or empty array if none
      #
      def warnings
        violations[:warnings] || []
      end

      # Returns the array of error messages.
      #
      # @return [Array<String>] Error messages, or empty array if none
      #
      def errors
        violations[:errors] || []
      end

      # Returns the array of info messages.
      #
      # @return [Array<String>] Info messages, or empty array if none
      #
      def messages
        violations[:messages] || []
      end

      # Checks if there are any violations present.
      #
      # @return [Boolean] true if any warnings, errors, or messages exist
      #
      def violations?
        warnings.any? || errors.any? || messages.any?
      end
    end
  end
end
