require "danger/plugin_support/plugin_parser"
require "danger/plugin_support/plugin_file_resolver"
require "danger/plugin_support/plugin_linter"

module Danger
  class PluginLint < CLAide::Command::Plugins
    self.summary = "Lints a plugin"
    self.command = "lint"

    attr_accessor :cork

    def initialize(argv)
      @warnings_as_errors = argv.flag?("warnings-as-errors", false)
      @refs = argv.arguments! unless argv.arguments.empty?
      @cork = Cork::Board.new(silent: argv.option("silent", false),
                              verbose: argv.option("verbose", false))
      super
    end

    self.summary = "Lint plugins from files, gems or the current folder. Outputs JSON array representation of Plugins on success."

    self.description = <<-DESC
      Converts a collection of file paths of Danger plugins into a JSON format.
      Note: Before 1.0, it will also parse the represented JSON to validate whether https://danger.systems would
      show the plugin on the website.
    DESC

    self.arguments = [
      CLAide::Argument.new("Paths, Gems or Nothing", false, true)
    ]

    def self.options
      [
        ["--warnings-as-errors", "Ensure strict linting."]
      ].concat(super)
    end

    def run
      file_resolver = PluginFileResolver.new(@refs)
      data = file_resolver.resolve

      parser = PluginParser.new(data[:paths], verbose: true)
      parser.parse
      json = parser.to_json

      linter = PluginLinter.new(json)
      linter.lint
      linter.print_summary(cork)

      abort("Failing due to errors\n".red) if linter.failed?
      abort("Failing due to warnings as errors\n".red) if @warnings_as_errors && !linter.warnings.empty?
    end
  end
end
