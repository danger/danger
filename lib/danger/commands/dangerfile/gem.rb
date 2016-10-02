require "claide_plugin"
require "danger/commands/dangerfile/init"

module Danger
  class DangerfileGem < DangerfileCommand
    self.summary = "Create a gem-based Dangerfile quickly."
    def self.description
      <<-DESC
                Creates a scaffold for the development of a new gem based Dangerfile
                named `NAME` according to the best practices.
      DESC
    end
    self.command = "gem"
    self.arguments = [
      CLAide::Argument.new("NAME", true)
    ]

    def initialize(argv)
      @name = argv.shift_argument
      prefix = "dangerfile" + "-"
      unless @name.nil? || @name.empty? || @name.start_with?(prefix)
        @name = prefix + @name.dup
      end
      @template_url = argv.shift_argument
      super
    end

    def validate!
      super
      if @name.nil? || @name.empty?
        help! "A name for the plugin is required."
      end

      help! "The plugin name cannot contain spaces." if @name =~ /\s/
    end

    def run
      runner = CLAide::TemplateRunner.new(@name, "https://github.com/danger/dangerfile-gem-template")
      runner.clone_template
      runner.configure_template
    end
  end
end
