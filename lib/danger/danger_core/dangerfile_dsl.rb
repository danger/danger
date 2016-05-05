require 'danger/danger_core/violation'

module Danger
  class Dangerfile
    # Anything inside this module is considered public API, and in the future
    # documentation will be generated from it via rdoc.

    module DSL
      # @!group Enviroment
      # @return [EnvironmentManager] Provides access to the raw Travis/Circle/Buildkite/GitHub
      # objects, which you can use to pull out extra bits of information. _Warning_
      # the interfaces of these objects is **not** considered a part of the Dangerfile public
      # API, and is viable to change occasionally on the whims of developers.

      attr_reader :env

      def initialize
        self.warnings = []
        self.errors = []
        self.messages = []
        self.markdowns = []

        load_default_plugins
      end

      # Download a local or remote plugin and use it locally
      #
      # @param    [String] path
      #           a local path or a https URL to the Ruby file to import
      #           a danger plugin from.
      def import(path)
        raise "`import` requires a string" unless path.kind_of?(String)
        path += ".rb" unless path.end_with?(".rb")

        if path.start_with?("http")
          import_url(path)
        else
          import_local(path)
        end
      end

      # Download a remote plugin and use it locally
      #
      # @param    [String] url
      #           https URL to the Ruby file to use
      def import_url(url)
        raise "URL is not https, for security reasons `danger` only supports encrypted requests" unless url.start_with?("https://")

        require 'tmpdir'
        require 'faraday'
        require 'faraday_middleware'

        @http_client ||= Faraday.new do |b|
          b.use FaradayMiddleware::FollowRedirects
          b.adapter :net_http
        end
        content = @http_client.get(url)

        Dir.mktmpdir do |dir|
          path = File.join(dir, "temporary_remote_action.rb")
          File.write(path, content.body)
          import_local(path)
        end
      end

      # Import one or more local plugins
      #
      # @param    [String] path
      #           The path to the file to import
      #           Can also be a pattern (./**/*plugin.rb)
      def import_local(path)
        Dir[path].each do |file|
          require File.expand_path(file) # without the expand_path it would fail if the path doesn't start with ./
        end
      end

      # Declares a CI blocking error
      #
      # @param    [String] message
      #           The message to present to the user
      # @param    [Boolean] sticky
      #           Whether the message should be kept after it was fixed,
      #           defaults to `true`.
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
      #           Whether the message should be kept after it was fixed,
      #           defaults to `true`.
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
      #           Whether the message should be kept after it was fixed,
      #           defaults to `true`.
      def message(message, sticky: true)
        self.messages << Violation.new(message, sticky)
        puts "Printing message '#{message}'"
      end

      # Print markdown to below the table
      #
      # @param    [String] message
      #           The markdown based message to be printed below the table
      def markdown(message)
        self.markdowns << message
        puts "Printing markdown #{message}"
      end

      private

      def should_ignore_violation(message)
        env.request_source.ignored_violations.include? message
      end

      # When an undefined method is called, we check to see if it's something
      # that the DSLs have, then starts looking at plugins support.
      def method_missing(method_sym, *arguments, &_block)
        core_dsls.each do |dsl|
          if dsl.public_methods.include?(method_sym)
            return dsl.send(method_sym)
          end
        end

        # Plugins
        class_name = method_sym.to_s.danger_class
        if Danger::Dangerfile::DSL.const_defined?(class_name)
          plugin_ref = Danger::Dangerfile::DSL.const_get(class_name)
          if plugin_ref < Plugin
            plugin_ref.new(self).run(*arguments)
          else
            raise "'#{method_sym}' is not a valid danger plugin".red
          end
        else
          raise "Unknown method '#{method_sym}', please check out the documentation for available plugins".red
        end
      end

      def load_default_plugins
        Dir["./lib/danger/plugins/*.rb"].each do |file|
          require File.expand_path(file)
        end

        Dir["./danger_plugins/*.rb"].each do |file|
          require File.expand_path(file)
        end
      end
    end
  end
end
