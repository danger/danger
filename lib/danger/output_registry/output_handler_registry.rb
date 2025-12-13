# frozen_string_literal: true

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
      # Catalog of all available handlers with their metadata.
      #
      # Each entry maps a handler identifier to metadata including:
      # - class_name: Fully qualified class name (String)
      # - platforms: Array of supported platforms (:github, :gitlab, etc.)
      # - description: Human-readable description of handler purpose
      #
      # Handler classes will be lazily loaded when first accessed.
      #
      # @note Handler classes referenced here will be implemented in Phase 2.
      #   The registry gracefully handles missing classes during Phase 1.
      #
      AVAILABLE_HANDLERS = {
        # GitHub Handlers
        github_check: {
          class_name: "Danger::OutputRegistry::Handlers::GitHub::GitHubCheckHandler",
          platforms: [:github],
          description: "Creates GitHub Check Run with annotations"
        },
        github_comment: {
          class_name: "Danger::OutputRegistry::Handlers::GitHub::GitHubCommentHandler",
          platforms: [:github],
          description: "Posts violations as GitHub PR comment"
        },
        github_inline: {
          class_name: "Danger::OutputRegistry::Handlers::GitHub::GitHubInlineCommentHandler",
          platforms: [:github],
          description: "Posts violations as GitHub inline PR comments"
        },
        github_status: {
          class_name: "Danger::OutputRegistry::Handlers::GitHub::GitHubCommitStatusHandler",
          platforms: [:github],
          description: "Updates GitHub commit status based on violations"
        },

        # GitLab Handlers (Phase 2 - not yet implemented)
        gitlab_inline: {
          class_name: "Danger::OutputRegistry::Handlers::GitLab::GitLabInlineCommentHandler",
          platforms: [:gitlab],
          description: "Posts violations as GitLab inline MR comments"
        },
        gitlab_comment: {
          class_name: "Danger::OutputRegistry::Handlers::GitLab::GitLabCommentHandler",
          platforms: [:gitlab],
          description: "Posts violations as GitLab MR discussion"
        },

        # Bitbucket Handlers (Phase 2 - not yet implemented)
        bitbucket_inline: {
          class_name: "Danger::OutputRegistry::Handlers::BitbucketCloud::BitbucketCloudInlineCommentHandler",
          platforms: [:bitbucket],
          description: "Posts violations as Bitbucket Cloud inline PR comments"
        },
        bitbucket_comment: {
          class_name: "Danger::OutputRegistry::Handlers::BitbucketCloud::BitbucketCloudCommentHandler",
          platforms: [:bitbucket],
          description: "Posts violations as Bitbucket Cloud PR comment"
        },

        # Local/Universal Handlers (Phase 3 - not yet implemented)
        console: {
          class_name: "Danger::OutputRegistry::Handlers::Universal::ConsoleHandler",
          platforms: %i(local github gitlab bitbucket),
          description: "Outputs violations to console/stdout"
        },
        json_file: {
          class_name: "Danger::OutputRegistry::Handlers::Universal::JSONFileHandler",
          platforms: %i(local github gitlab bitbucket),
          description: "Writes violations to JSON file"
        },
        junit_xml: {
          class_name: "Danger::OutputRegistry::Handlers::Universal::JUnitXMLHandler",
          platforms: %i(local github gitlab bitbucket),
          description: "Writes violations in JUnit XML format"
        },
        markdown_summary: {
          class_name: "Danger::OutputRegistry::Handlers::Universal::MarkdownSummaryHandler",
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
      # @param name [Symbol] Handler identifier from AVAILABLE_HANDLERS
      # @return [OutputHandler, nil] Handler instance, or nil if handler
      #   doesn't exist or class cannot be loaded
      #
      # @example Get a specific handler
      #   handler = registry.handler(:github_status)
      #   handler.execute if handler
      #
      def handler(name)
        handler_metadata = AVAILABLE_HANDLERS[name]
        return nil unless handler_metadata

        begin
          handler_class = constantize(handler_metadata[:class_name])
          handler_class.new(@context, @violations)
        rescue NameError
          # Handler class doesn't exist yet (Phase 1)
          # In production this would log: warn "Handler class not found: #{handler_metadata[:class_name]}"
          nil
        end
      end

      # Returns list of all available handler identifiers.
      #
      # @return [Array<Symbol>] Array of handler names
      #
      # @example List all handlers
      #   registry.available_handlers
      #   # => [:github_status, :github_check, :github_comment, ...]
      #
      def available_handlers
        AVAILABLE_HANDLERS.keys
      end

      # Returns handlers that support the specified platform.
      #
      # @param platform [Symbol] Platform identifier (:github, :gitlab, :bitbucket, :local)
      # @return [Array<Symbol>] Array of handler names supporting the platform
      #
      # @example Get GitHub handlers
      #   registry.handlers_for_platform(:github)
      #   # => [:github_status, :github_check, :github_comment, :console, :json_file, ...]
      #
      def handlers_for_platform(platform)
        AVAILABLE_HANDLERS.select do |_name, metadata|
          metadata[:platforms].include?(platform)
        end.keys
      end

      # Returns the default handlers for a given platform.
      #
      # Default handlers are the recommended set for each platform,
      # balancing functionality and performance.
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
        handler_names = case platform
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

        # Instantiate handlers, filtering out any that don't exist yet
        handler_names.map { |name| handler(name) }.compact
      end

      private

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
        return :github if ENV["GITHUB_ACTIONS"] || github_platform?
        return :gitlab if ENV["GITLAB_CI"] || gitlab_platform?
        return :bitbucket if bitbucket_platform?

        :local
      end

      # Checks if context indicates GitHub platform.
      #
      # @return [Boolean]
      #
      def github_platform?
        return false unless @context&.env&.request_source

        @context.env.request_source.class.name.include?("GitHub")
      end

      # Checks if context indicates GitLab platform.
      #
      # @return [Boolean]
      #
      def gitlab_platform?
        return false unless @context&.env&.request_source

        @context.env.request_source.class.name.include?("GitLab")
      end

      # Checks if context indicates Bitbucket platform.
      #
      # @return [Boolean]
      #
      def bitbucket_platform?
        return false unless @context&.env&.request_source

        @context.env.request_source.class.name.include?("Bitbucket")
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

      # Converts a string class name to a constant.
      #
      # @param class_name [String] Fully qualified class name
      # @return [Class] The class constant
      # @raise [NameError] if class doesn't exist
      #
      def constantize(class_name)
        class_name.split("::").reduce(Object) do |mod, name|
          mod.const_get(name)
        end
      end
    end
  end
end
