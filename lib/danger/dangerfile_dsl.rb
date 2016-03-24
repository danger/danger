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
        load_default_plugins
      end

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
        content = Faraday.get(url)
        Dir.mktmpdir do |dir|
          path = File.join(dir, "remote_action.rb")
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
      def fail(message)
        return if should_ignore_violation(message)
        self.errors << message
        puts "Raising error '#{message}'"
      end

      # Specifies a problem, but not critical
      #
      # @param    [String] message
      #           The message to present to the user
      def warn(message)
        return if should_ignore_violation(message)
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

      private
      def load_default_plugins
        Dir['./lib/danger/plugins/*.rb'].each do |file|
          require file
        end
      end
    end
  end
end
