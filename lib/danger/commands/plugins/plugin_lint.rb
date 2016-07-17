require "danger/plugin_support/plugin_parser"
require "danger/plugin_support/plugin_file_resolver"
require "danger/plugin_support/plugin_linter"

module Danger
  class PluginLint < CLAide::Command::Plugins
    self.summary = "Lints a plugin"
    self.command = "lint"

    attr_accessor :cork

    def initialize(argv)
      @refs = argv.arguments! unless argv.arguments.empty?
      @cork = Cork::Board.new(silent: argv.option("silent", false),
                              verbose: argv.option("verbose", false))
      super
    end

    self.summary = "Lint plugins from files, gems or the current folder. Outputs JSON array representation of Plugins on success."

    self.description = <<-DESC
      Converts a collection of file paths of Danger plugins into a JSON format.
      Note: Before 1.0, it will also parse the represented JSON to validate whether http://danger.systems would
      show the plugin on the website.
    DESC

    self.arguments = [
      CLAide::Argument.new("Paths, Gems or Nothing", false, true)
    ]

    def run
      file_resolver = PluginFileResolver.new(@refs)
      paths = file_resolver.resolve_to_paths

      parser = PluginParser.new(paths, verbose: true)
      parser.parse
      json = parser.to_json

      linter = PluginLinter.new(json)
      linter.lint
      linter.print_summary(cork)

      exit(1) if linter.failed?
    end
  end
end
