require "danger/danger_core/standard_error"

module Danger
  class DangerfileJS
    attr_accessor :env, :verbose, :ui, :runtime

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the Dangerfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    def initialize(env_manager, cork_board)
      abort("Sorry - you cannot run JavaScript Dangerfiles on Windows servers".red) if Gem.win_platform?

      # This is here because the gem might not be included
      # if you have vanilla Ruby Danger.
      require "therubyracer"

      @ui = cork_board
      @env = env_manager

      ten_min = 1000 * 60 * 10
      @runtime = V8::Context.new timeout: ten_min
      env_manager.setup_plugins(self)

      setup_js_env
    end

    def setup_js_env
      # Add lodash into the runner, so that there is something to work
      # with when using the default objects
      lodash_path = File.join(Danger.gem_path, "lib/danger/danger_core/js/vendor/lodash.min.js")
      lodash = File.read(lodash_path)
      runtime.eval(lodash)
    end

    def extend_with_plugins(plugin_host)
      # Create attributes for all of the external plugins
      plugin_host.external_plugins.each do |plugin|
        name = plugin.class.instance_name
        self.class.send(:attr_reader, name)
        runtime[name] = plugin
      end

      # Expose the methods for all of the core functions
      plugin_host.core_plugins.each do |plugin|
        plugin.public_methods(false).each do |core_method|
          runtime[core_method.to_s] = plugin.method(core_method)
        end
      end
    end

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      "DangerfileJS"
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

      self.defined_in_file = path

      # this might not be needed
      # @js = CommonJS::Environment.new(runtime, path: path)

      # rubocop:disable Lint/RescueException
      begin
        runtime.eval(contents)
        # rubocop:enable Eval
      rescue Exception => e
        message = "Invalid `#{path.basename}` file: #{e.message}"
        raise DSLError.new(message, path, e.backtrace, contents)
      end
      # rubocop:enable Lint/RescueException
    end
  end
end
