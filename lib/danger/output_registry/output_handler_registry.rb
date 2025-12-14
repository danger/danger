# frozen_string_literal: true

require_relative "output_handler"

# Load implemented handlers
Dir.glob("#{__dir__}/handlers/*/*.rb").sort.each { |file| require file }

module Danger
  module OutputRegistry
    # Registry for discovering and executing output handlers.
    #
    # OutputHandlerRegistry manages the lifecycle of output handlers, including
    # discovery, instantiation, and execution. It provides platform-aware handler
    # selection and supports both default and custom handler configurations.
    #
    # The registry maintains a catalog of all available handlers and their metadata,
    # including which platforms they support and how to instantiate them.
    #
    # @example Basic usage with auto-detection
    #   registry = OutputHandlerRegistry.new
    #   registry.set_context(danger)
    #   registry.set_violations({ warnings: ["issue"], errors: [], messages: [] })
    #
    #   # Get default handlers for current platform
    #   handlers = registry.default_handlers_for_platform(registry.send(:detect_platform))
    #   handlers.each { |h| h.execute }
    #
    # @example Custom handler selection
    #   registry = OutputHandlerRegistry.new
    #   registry.set_context(danger)
    #   registry.set_violations(violations)
    #
    #   # Use specific handler
    #   handler = registry.handler(:github_status)
    #   handler.execute if handler
    #
    class OutputHandlerRegistry
      # Class-level registry for custom handlers registered by external gems or applications.
      @custom_handlers = {}

      class << self
        # Registers a custom output handler.
        #
        # This allows external gems and applications to add their own handlers
        # without modifying the Danger gem source code.
        #
        # @param name [Symbol] Unique identifier for the handler
        # @param handler_class [Class] The handler class (must inherit from OutputHandler)
        # @param platforms [Array<Symbol>, Symbol] Supported platforms (:github, :gitlab, :bitbucket, :local)
        # @param description [String] Human-readable description
        # @param include_in_defaults [Boolean] Whether to include in default handlers for platforms (default: false)
        # @return [void]
        #
        # @example Register a custom Slack handler from a gem
        #   Danger::OutputRegistry::OutputHandlerRegistry.register(
        #     :slack_notifications,
        #     MyGem::SlackHandler,
        #     platforms: [:github, :gitlab],
        #     description: "Posts violations to Slack"
        #   )
        #
        # @example Register handler that runs automatically with defaults
        #   Danger::OutputRegistry::OutputHandlerRegistry.register(
        #     :audit_logger,
        #     MyCompany::AuditHandler,
        #     platforms: [:github],
        #     include_in_defaults: true
        #   )
        #
        # @example Register in a Rails initializer
        #   # config/initializers/danger.rb
        #   Danger::OutputRegistry::OutputHandlerRegistry.register(
        #     :internal_dashboard,
        #     MyCompany::DashboardHandler,
        #     platforms: [:github]
        #   )
        #
        def register(name, handler_class, platforms:, description: "Custom handler", include_in_defaults: false)
          @custom_handlers[name.to_sym] = {
            class: handler_class,
            platforms: Array(platforms).map(&:to_sym),
            description: description,
            include_in_defaults: include_in_defaults
          }
        end

        # Unregisters a handler by name.
        #
        # Can be used to remove custom handlers or disable built-in handlers.
        #
        # @param name [Symbol] Handler identifier to remove
        # @return [Hash, nil] The removed handler metadata, or nil if not found
        #
        # @example Remove a custom handler
        #   OutputHandlerRegistry.unregister(:slack_notifications)
        #
        def unregister(name)
          @custom_handlers.delete(name.to_sym)
        end

        # Returns all registered custom handlers.
        #
        # @return [Hash<Symbol, Hash>] Map of handler names to metadata
        #
        def custom_handlers
          @custom_handlers ||= {}
        end

        # Resets custom handler registry to empty state.
        #
        # Primarily useful for testing to ensure clean state between tests.
        #
        # @return [void]
        #
        def reset_custom_handlers!
          @custom_handlers = {}
        end
      end

      # Catalog of all available handlers with their metadata.
      #
      # Each entry maps a handler identifier to metadata including:
      # - class: The handler class (must inherit from OutputHandler)
      # - platforms: Array of supported platforms (:github, :gitlab, etc.)
      # - description: Human-readable description of handler purpose
      #
      AVAILABLE_HANDLERS = {
        # GitHub Handlers
        github_check: {
          class: Handlers::GitHub::GitHubCheckHandler,
          platforms: [:github],
          description: "Creates GitHub Check Run with annotations"
        },
        github_comment: {
          class: Handlers::GitHub::GitHubCommentHandler,
          platforms: [:github],
          description: "Posts violations as GitHub PR comment"
        },
        github_inline: {
          class: Handlers::GitHub::GitHubInlineCommentHandler,
          platforms: [:github],
          description: "Posts violations as GitHub inline PR comments"
        },
        github_status: {
          class: Handlers::GitHub::GitHubCommitStatusHandler,
          platforms: [:github],
          description: "Updates GitHub commit status based on violations"
        },

        # GitLab Handlers
        gitlab_inline: {
          class: Handlers::GitLab::GitLabInlineCommentHandler,
          platforms: [:gitlab],
          description: "Posts violations as GitLab inline MR comments"
        },
        gitlab_comment: {
          class: Handlers::GitLab::GitLabCommentHandler,
          platforms: [:gitlab],
          description: "Posts violations as GitLab MR discussion"
        },

        # Bitbucket Cloud Handlers
        bitbucket_inline: {
          class: Handlers::BitbucketCloud::BitbucketCloudInlineCommentHandler,
          platforms: [:bitbucket],
          description: "Posts violations as Bitbucket Cloud inline PR comments"
        },
        bitbucket_comment: {
          class: Handlers::BitbucketCloud::BitbucketCloudCommentHandler,
          platforms: [:bitbucket],
          description: "Posts violations as Bitbucket Cloud PR comment"
        },

        # Universal Handlers
        console: {
          class: Handlers::Universal::ConsoleHandler,
          platforms: %i(local github gitlab bitbucket),
          description: "Outputs violations to console/stdout"
        },
        json_file: {
          class: Handlers::Universal::JSONFileHandler,
          platforms: %i(local github gitlab bitbucket),
          description: "Writes violations to JSON file"
        },
        junit_xml: {
          class: Handlers::Universal::JUnitXMLHandler,
          platforms: %i(local github gitlab bitbucket),
          description: "Writes violations in JUnit XML format"
        },
        markdown_summary: {
          class: Handlers::Universal::MarkdownSummaryHandler,
          platforms: %i(local github gitlab bitbucket),
          description: "Generates markdown summary of violations"
        }
      }.freeze

      # Initializes a new registry instance.
      #
      def initialize
        @context = nil
        @violations = nil
      end

      # Sets the Danger context for handler execution.
      #
      # @param context [Danger::DangerfileContext] The Danger context
      # @return [void]
      #
      attr_writer :context

      # Sets the violations to be processed by handlers.
      #
      # @param violations [Hash] Hash containing violation arrays:
      #   - :warnings [Array<String>] Warning messages
      #   - :errors [Array<String>] Error messages
      #   - :messages [Array<String>] Info messages
      # @return [void]
      #
      attr_writer :violations

      # Instantiates a specific handler by name.
      #
      # Looks up handlers in both built-in AVAILABLE_HANDLERS and custom
      # handlers registered via {.register}. Custom handlers take precedence
      # if there's a name conflict.
      #
      # @param name [Symbol] Handler identifier
      # @return [OutputHandler, nil] Handler instance, or nil if handler
      #   doesn't exist or class cannot be loaded
      #
      # @example Get a built-in handler
      #   handler = registry.handler(:github_status)
      #   handler.execute if handler
      #
      # @example Get a custom registered handler
      #   handler = registry.handler(:slack_notifications)
      #   handler.execute if handler
      #
      def handler(name)
        name = name.to_sym

        # Custom handlers take precedence over built-ins
        metadata = self.class.custom_handlers[name] || AVAILABLE_HANDLERS[name]
        return nil unless metadata

        metadata[:class].new(@context, @violations)
      end

      # Returns list of all available handler identifiers.
      #
      # Includes both built-in handlers and custom registered handlers.
      #
      # @return [Array<Symbol>] Array of handler names
      #
      # @example List all handlers
      #   registry.available_handlers
      #   # => [:github_status, :github_check, :slack_notifications, ...]
      #
      def available_handlers
        (AVAILABLE_HANDLERS.keys + self.class.custom_handlers.keys).uniq
      end

      # Returns handlers that support the specified platform.
      #
      # Includes both built-in and custom registered handlers.
      #
      # @param platform [Symbol] Platform identifier (:github, :gitlab, :bitbucket, :local)
      # @return [Array<Symbol>] Array of handler names supporting the platform
      #
      # @example Get GitHub handlers
      #   registry.handlers_for_platform(:github)
      #   # => [:github_status, :github_check, :github_comment, :slack_notifications, ...]
      #
      def handlers_for_platform(platform)
        platform = platform.to_sym

        builtin = AVAILABLE_HANDLERS.select do |_name, metadata|
          metadata[:platforms].include?(platform)
        end.keys

        custom = self.class.custom_handlers.select do |_name, metadata|
          metadata[:platforms].include?(platform)
        end.keys

        (builtin + custom).uniq
      end

      # Returns the default handlers for a given platform.
      #
      # Default handlers are the recommended set for each platform,
      # balancing functionality and performance. Also includes custom
      # handlers registered with `include_in_defaults: true`.
      #
      # @param platform [Symbol] Platform identifier
      # @return [Array<OutputHandler>] Array of instantiated default handlers
      #   (empty if handlers don't exist yet)
      #
      # @example Get default GitHub handlers
      #   handlers = registry.default_handlers_for_platform(:github)
      #   handlers.each(&:execute)
      #
      def default_handlers_for_platform(platform)
        platform = platform.to_sym

        builtin_names = case platform
                        when :github
                          default_github_handlers
                        when :gitlab
                          default_gitlab_handlers
                        when :bitbucket
                          default_bitbucket_handlers
                        when :local
                          default_local_handlers
                        else
                          [:console]
                        end

        # Add custom handlers that opted into defaults for this platform
        custom_default_names = self.class.custom_handlers.select do |_name, metadata|
          metadata[:include_in_defaults] && metadata[:platforms].include?(platform)
        end.keys

        handler_names = builtin_names + custom_default_names

        # Instantiate handlers, filtering out any that don't exist yet
        handler_names.map { |name| handler(name) }.compact
      end

      private

      # Platform detection mapping: platform symbol to detection logic.
      # Each detector receives the request_source and returns true if it matches.
      PLATFORM_DETECTORS = {
        github: ->(source) { source.class.name.include?("GitHub") },
        gitlab: ->(source) { source.class.name.include?("GitLab") },
        bitbucket: ->(source) { source.class.name.include?("Bitbucket") }
      }.freeze

      # Environment variable mappings for CI/CD detection.
      # Maps platform to environment variable that indicates that platform.
      PLATFORM_ENV_VARS = {
        github: "GITHUB_ACTIONS",
        gitlab: "GITLAB_CI"
      }.freeze

      # Detects the current platform based on environment and context.
      #
      # Detection priority:
      # 1. GitHub Actions env or GitHub request source
      # 2. GitLab CI env or GitLab request source
      # 3. Bitbucket request source
      # 4. Local (fallback)
      #
      # @return [Symbol] Detected platform (:github, :gitlab, :bitbucket, or :local)
      #
      def detect_platform
        # Check environment variables first (faster)
        PLATFORM_ENV_VARS.each { |platform, env_var| return platform if ENV[env_var] }

        # Fall back to request source detection
        request_source = @context&.env&.request_source
        return :local unless request_source

        detected = PLATFORM_DETECTORS.find { |_, detector| detector.call(request_source) }
        detected ? detected.first : :local
      end

      # Returns default handler names for GitHub platform.
      #
      # @return [Array<Symbol>]
      #
      def default_github_handlers
        %i(github_check console)
      end

      # Returns default handler names for GitLab platform.
      #
      # @return [Array<Symbol>]
      #
      def default_gitlab_handlers
        %i(gitlab_inline console)
      end

      # Returns default handler names for Bitbucket platform.
      #
      # @return [Array<Symbol>]
      #
      def default_bitbucket_handlers
        %i(bitbucket_inline console)
      end

      # Returns default handler names for local platform.
      #
      # @return [Array<Symbol>]
      #
      def default_local_handlers
        %i(console markdown_summary)
      end
    end
  end
end
