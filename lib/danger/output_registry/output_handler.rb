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

      # Alias for violations? for backwards compatibility.
      #
      # @return [Boolean] true if any violations exist
      #
      alias has_violations? violations?

      # Logs a warning message.
      #
      # Uses the UI mechanism from context if available, falls back to puts.
      #
      # @param message [String] The message to log
      # @return [void]
      #
      def log_warning(message)
        if @context&.ui.respond_to?(:warn)
          @context.ui.warn(message)
        else
          puts("⚠️  #{message}")
        end
      end

      # Filters violations by a given condition.
      #
      # Returns a hash of violations filtered by the provided condition block.
      # The condition is applied to each violation to determine inclusion.
      #
      # @example Filter violations with file information
      #   violations = filter_violations { |v| v.file && v.line }
      #
      # @example Filter violations without file information
      #   violations = filter_violations { |v| v.file.nil? }
      #
      # @yield [violation] Each violation is passed to the block
      # @yieldparam violation [Object] A violation object
      # @yieldreturn [Boolean] true to include the violation, false to exclude
      #
      # @return [Hash<Symbol, Array>] Hash with :warnings, :errors, :messages keys
      #
      def filter_violations
        return {} unless block_given?

        {
          warnings: warnings.select { |v| yield(v) },
          errors: errors.select { |v| yield(v) },
          messages: messages.select { |v| yield(v) }
        }
      end

      # Gets the GitHub request source if this is a GitHub context.
      #
      # @return [Danger::RequestSources::GitHub, nil] The GitHub request source, or nil if not GitHub
      #
      def github_request_source
        request_source = @context&.env&.request_source
        return nil unless request_source&.kind_of?(::Danger::RequestSources::GitHub)

        request_source
      end

      # Checks if this is a GitHub context.
      #
      # @return [Boolean] true if the context is GitHub
      #
      def github?
        !github_request_source.nil?
      end
    end
  end
end
