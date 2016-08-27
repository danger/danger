# So much was ripped direct from CocoaPods-Core - thanks!

require "danger/danger_core/standard_error"

module Danger
  class Dangerfile
    attr_accessor :env, :verbose, :ui

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the Dangerfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    def initialize(env_manager, cork_board)
      @ui = cork_board
      @env = env_manager
      env_manager.setup_plugins(self)
    end

    def extend_with_plugins(plugin_host)
      # Create attributes for all of the external plugins
      plugin_host.external_plugins.each do |plugin|
        name = plugin.class.instance_name
        self.class.send(:attr_reader, name)
        instance_variable_set("@#{name}", plugin)
      end

      # Keep track fo this for `method_missing`
      @core_plugins = plugin_host.core_plugins
    end

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      "Dangerfile"
    end

    # Both of these methods exist on all objects
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-warn
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-fail
    # However, as we're using using them in the DSL, they won't
    # get method_missing called correctly without overriding them.

    def warn(*args, &blk)
      method_missing(:warn, *args, &blk)
    end

    def fail(*args, &blk)
      method_missing(:fail, *args, &blk)
    end

    # When an undefined method is called, we check to see if it's something
    # that the core DSLs have, then starts looking at plugin support.

    # rubocop:disable Style/MethodMissing

    def method_missing(method_sym, *arguments, &_block)
      @core_plugins.each do |plugin|
        if plugin.public_methods(false).include?(method_sym)
          return plugin.send(method_sym, *arguments)
        end
      end
      super
    end

    # Parses the file at a path, optionally takes the content of the file for DI
    #
    def parse(path, contents = nil)
      contents ||= File.open(path, "r:utf-8", &:read)

      # Work around for Rubinius incomplete encoding in 1.9 mode
      if contents.respond_to?(:encoding) && contents.encoding.name != "UTF-8"
        contents.encode!("UTF-8")
      end

      if contents.tr!("“”‘’‛", %(""'''))
        # Changes have been made
        ui.puts "Your #{path.basename} has had smart quotes sanitised. " \
          "To avoid issues in the future, you should not use " \
          "TextEdit for editing it. If you are not using TextEdit, " \
          "you should turn off smart quotes in your editor of choice.".red
      end

      if contents.include?("puts")
        ui.puts "You used `puts` in your Dangerfile. To print out text to GitHub use `message` instead"
      end

      self.defined_in_file = path
      instance_eval do
        # rubocop:disable Lint/RescueException
        begin
          # rubocop:disable Eval
          eval(contents, nil, path.to_s)
          # rubocop:enable Eval
        rescue Exception => e
          message = "Invalid `#{path.basename}` file: #{e.message}"
          raise DSLError.new(message, path, e.backtrace, contents)
        end
        # rubocop:enable Lint/RescueException
      end
    end

    # Mainly a helper method for `local --pry`
    def plugins
      env.plugin_host.plugins.values
    end
  end
end
