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
      # Default options for handler execution.
      DEFAULT_OPTIONS = {
        danger_id: "danger",
        new_comment: false,
        remove_previous_comments: false,
        markdowns: []
      }.freeze

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
      # @param options [Hash] Optional execution options:
      #   - :danger_id [String] Identifier for Danger comments (default: "danger")
      #   - :new_comment [Boolean] Create new comment vs update existing (default: false)
      #   - :remove_previous_comments [Boolean] Delete old Danger comments (default: false)
      #   - :markdowns [Array] Markdown content to include
      #
      # @return [void]
      #
      # @example Execute a handler
      #   MyHandler.execute(danger, { warnings: ["issue"], errors: [], messages: [] })
      #
      # @example Execute with options
      #   MyHandler.execute(danger, violations, danger_id: "my-danger", new_comment: true)
      #
      def self.execute(context, violations, **options)
        handler = new(context, violations, **options)
        handler.execute if handler.enabled?
      end

      # Initializes a new handler instance.
      #
      # @param context [Danger::DangerfileContext] The Danger context
      # @param violations [Hash] Hash containing violation arrays
      # @param options [Hash] Optional execution options (see {.execute})
      #
      def initialize(context, violations, **options)
        @context = context
        @violations = violations
        @options = DEFAULT_OPTIONS.merge(options)
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

      # @!attribute [r] options
      #   @return [Hash] The execution options
      attr_reader :options

      # Returns the danger_id for identifying Danger-generated content.
      #
      # @return [String] The danger identifier (default: "danger")
      #
      def danger_id
        @options[:danger_id]
      end

      # Whether to create a new comment instead of updating existing.
      #
      # @return [Boolean] true to create new, false to update existing
      #
      def new_comment?
        @options[:new_comment]
      end

      # Whether to remove previous Danger comments.
      #
      # @return [Boolean] true to remove previous comments
      #
      def remove_previous_comments?
        @options[:remove_previous_comments]
      end

      # Returns the markdown content to include in output.
      #
      # @return [Array] Markdown objects
      #
      def markdowns
        @options[:markdowns] || []
      end

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
      def filter_violations(&condition)
        return {} unless condition

        {
          warnings: warnings.select(&condition),
          errors: errors.select(&condition),
          messages: messages.select(&condition)
        }
      end

      # Gets the GitHub request source if this is a GitHub context.
      #
      # @return [Danger::RequestSources::GitHub, nil] The GitHub request source, or nil if not GitHub
      #
      def github_request_source
        request_source = @context&.env&.request_source
        return nil unless request_source.kind_of?(::Danger::RequestSources::GitHub)

        request_source
      end

      # Checks if this is a GitHub context.
      #
      # @return [Boolean] true if the context is GitHub
      #
      def github?
        !github_request_source.nil?
      end

      # Returns all violations as a single flat array.
      #
      # Combines errors, warnings, and messages into one array for cases
      # where violation type doesn't matter and you just need all issues.
      #
      # @return [Array] Array of all violations in order: errors, warnings, messages
      #
      def all_violations
        errors + warnings + messages
      end

      # Extracts GitHub PR metadata from the request source.
      #
      # Provides consistent access to commonly used GitHub PR information
      # across handlers to avoid duplicating extraction logic.
      #
      # @return [Hash] Hash with :client, :repo_slug, :commit_sha, :pr_number
      # @return [nil] if not a GitHub context
      #
      def github_pr_metadata
        request_source = github_request_source
        return nil unless request_source

        {
          client: request_source.client,
          repo_slug: request_source.repo_slug,
          commit_sha: request_source.pr_json["head"]["sha"],
          pr_number: request_source.pr_json["number"]
        }
      end

      # Maps violation type to a specific attribute from TYPE_MAPPINGS.
      #
      # Provides unified, consistent access to violation type metadata like
      # emojis and annotation levels, avoiding duplicate lookup logic across handlers.
      #
      # @param type [Symbol] Violation type (:error, :warning, :message)
      # @param key [Symbol] The attribute to extract (:emoji, :annotation_level, etc.)
      # @return [String] The mapped value (emoji or annotation level)
      #
      # @example Get emoji for error
      #   violation_type_mapping(:error, :emoji) => "🚫"
      #
      # @example Get annotation level for warning
      #   violation_type_mapping(:warning, :annotation_level) => "warning"
      #
      def violation_type_mapping(type, key)
        require_relative "handlers/github/github_config"

        mapping = Handlers::GitHub::GitHubConfig::TYPE_MAPPINGS[type] ||
                  Handlers::GitHub::GitHubConfig::TYPE_MAPPINGS[:message]
        mapping[key]
      end
    end
  end
end
