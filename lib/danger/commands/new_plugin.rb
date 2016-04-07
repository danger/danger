module Danger
  class NewPlugin < Runner
    self.summary = 'Generate a new danger plugin.'
    self.command = 'new_plugin'

    def initialize(argv)
      super
    end

    def validate!
      super
    end

    def run
      require 'fileutils'

      puts "Must be lower case, and use a '_' between words. Do not use '.'".green
      puts "examples: 'number_of_emojis', 'ensure_pr_title_contains_keyword'".green
      puts "Name of your new plugin: "
      name = STDIN.gets.strip

      dir = Danger.gem_path
      content = File.read(File.join(dir, "lib", "assets", "PluginTemplate.rb.template"))
      content.gsub!("[[CLASS_NAME]]", name.danger_class)

      plugins_path = "danger_plugins"
      FileUtils.mkdir_p("plugins_path") unless File.directory?(plugins_path)

      output_path = File.join(plugins_path, "#{name}.rb")
      raise "File '#{output_path}' already exists!" if File.exist?(output_path)
      File.write(output_path, content)

      puts ""
      puts "Successfully created new plugin at path '#{output_path}'".green
      puts "Add this to your `Dangerfile` to use it:"
      puts ""
      puts "#{name}(parameter1: 123, parameter2: \"Club Mate\")".blue
      puts ""
      puts "Enjoy ✨"
    end
  end
end
