require "claide/command/plugins_helper"
require "claide/executable"

module Danger
  class PluginGem < CLAide::Command::Plugins
    # Creates a gem based on https://github.com/danger/dangerfile-gem-template
    self.summary = "Creates a new gem"
    self.command = "gem"

    self.description = <<-DESC
      Creates a scaffold for the development of a new danger gem
      named `NAME` according to the best practices.

      If a `TEMPLATE_URL`, pointing to a git repo containing a
      compatible template, is specified, it will be used
      in place of the default one.
    DESC

    self.arguments = [
      CLAide::Argument.new("NAME", true),
      CLAide::Argument.new("TEMPLATE_URL", false)
    ]

    def initialize(argv)
      @name = argv.shift_argument
      prefix = "dangerfile-"
      @name = prefix + @name unless @name.nil? || @name.empty? || @name.start_with?(prefix)
      @template_url = argv.shift_argument
      super
    end

    def validate!
      super
      if @name.nil? || @name.empty?
        help! "A name for the gem is required."
      end

      help! "The gem name cannot contain spaces." if @name =~ /\s/
    end

    def run
      clone_template
      configure_template
    end

    #----------------------------------------#

    private

    # !@group Private helpers

    extend CLAide::Executable
    executable :git

    # Clones the template from the remote in the working directory using
    # the name of the plugin.
    #
    # @return [void]
    #
    def clone_template
      UI.section("-> Creating `#{@name}` gem") do
        UI.notice "using template '#{template_repo_url}'"
        command = ["clone", template_repo_url, @name]
        git! command
      end
    end

    # Runs the template configuration utilities.
    #
    # @return [void]
    #
    def configure_template
      UI.section("-> Configuring gem") do
        Dir.chdir(@name) do
          if File.file? "configure"
            system "./configure #{@name}"
          else
            UI.warn "Template does not have a configure file."
          end
        end
      end
    end

    # Checks if a template URL is given else returns the Plugins.config URL
    #
    # @return String
    #
    def template_repo_url
      @template_url || "https://github.com/danger/dangerfile-gem-template"
    end
  end
end
