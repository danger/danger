# So much was ripped direct from CocoaPods-Core - thanks!

require 'danger/danger_core/dangerfile_dsl'
require 'danger/danger_core/standard_error'

require 'danger/danger_core/plugins/dangerfile_messaging_plugin'
require 'danger/danger_core/plugins/dangerfile_import_plugin'
require 'danger/danger_core/plugins/dangerfile_git_plugin'
require 'danger/danger_core/plugins/dangerfile_github_plugin'

module Danger
  class Dangerfile
    include Danger::Dangerfile::DSL

    attr_accessor :env, :verbose, :plugins

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the Dangerfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      'Dangerfile'
    end

    # These are the classes that are allowed to also use method_missing
    # in order to provide broader plugin support
    def core_plugins_classes
      [
        Danger::DangerfileMessagingPlugin,
        Danger::DangerfileImportPlugin,
        Danger::DangerfileGitHubPlugin,
        Danger::DangerfileGitPlugin
      ]
    end

    # Both of these methods exist on all objects
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-warn
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-fail
    # However, as we're using using them in the DSL, they won't
    # get method_missing called.

    def warn(message)
      method_missing(:warn, message)
    end

    def fail(message)
      method_missing(:fail, message)
    end

    # When an undefined method is called, we check to see if it's something
    # that the DSLs have, then starts looking at plugins support.
    def method_missing(method_sym, *arguments, &_block)
      @core_plugins.each do |plugin|
        if plugin.public_methods(false).include?(method_sym)
          return plugin.send(method_sym, *arguments)
        end
      end
      super
    end

    def initialize(env_manager)
      @plugins = {}
      @core_plugins = []

      # Triggers the core plugins
      @env = env_manager
      refresh_plugins
    end

    # Iterate through available plugin classes and initialize them with
    # a reference to this Dangerfile
    def refresh_plugins
      plugins = ObjectSpace.each_object(Class).select { |klass| klass < Danger::Plugin }
      plugins.map do |klass|
        plugin = klass.new(self)
        next if plugin.nil? || @plugins[klass]

        name = plugin.class.instance_name
        self.singleton_class.instance_eval { attr_reader name.to_sym }
        instance_variable_set("@#{name}", plugin)

        @plugins[klass] = plugin
        @core_plugins << plugin if core_plugins_classes.include? klass
      end
    end
    alias init_plugins refresh_plugins

    # TODO: Needs tests
    # Iterates through the DSL's attributes, and table's the output
    def print_known_info
      rows = []

      attributes = public_methods(false)
      attributes.each do |key|
        value = self.send(key)
        value = value.scan(/.{,80}/).to_a.each(&:strip!).join("\n") if key == :pr_body

        # So that we either have one value per row
        # or we have [] for an empty array
        value = value.join("\n") if value.kind_of?(Array) && value.count > 0

        rows << [key.to_s, value]
      end

      rows << ["---", "---"]
      rows << ["SCM", env.scm.class]
      rows << ["Source", env.ci_source.class]
      rows << ["Requests", env.request_source.class]
      rows << ["Base Commit", env.meta_info_for_base]
      rows << ["Head Commit", env.meta_info_for_head]

      params = {}
      params[:rows] = rows.each { |current| current[0] = current[0].yellow }
      params[:title] = "Danger v#{Danger::VERSION}\nDSL Attributes".green

      puts ""
      puts Terminal::Table.new(params)
      puts ""
    end

    # Parses the file at a path, optionally takes the content of the file for DI
    #
    def parse(path, contents = nil)
      print_known_info if verbose

      contents ||= File.open(path, 'r:utf-8', &:read)

      # Work around for Rubinius incomplete encoding in 1.9 mode
      if contents.respond_to?(:encoding) && contents.encoding.name != 'UTF-8'
        contents.encode!('UTF-8')
      end

      if contents.tr!('“”‘’‛', %(""'''))
        # Changes have been made
        puts "Your #{path.basename} has had smart quotes sanitised. " \
                    'To avoid issues in the future, you should not use ' \
                    'TextEdit for editing it. If you are not using TextEdit, ' \
                    'you should turn off smart quotes in your editor of choice.'.red
      end

      if contents.include?("puts")
        puts "You used `puts` in your Dangerfile. To print out text to GitHub use `message` instead"
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

    def print_results
      status = status_report
      return if (status[:errors] + status[:warnings] + status[:messages] + status[:markdowns]).count == 0

      puts ""
      puts "danger results:"
      [:errors, :warnings, :messages].each do |current|
        params = {}
        params[:rows] = status[current].map { |item| [item] }
        next unless params[:rows].count > 0
        params[:title] = case current
                         when :errors
                           current.to_s.capitalize.red
                         when :warnings
                           current.to_s.capitalize.yellow
                         else
                           current.to_s.capitalize
                         end

        puts ""
        puts Terminal::Table.new(params)
        puts ""
      end

      puts "Markdown: ".green if status[:markdowns].count > 0
      status[:markdowns].each do |current_markdown|
        puts current_markdown
      end
    end
  end
end
