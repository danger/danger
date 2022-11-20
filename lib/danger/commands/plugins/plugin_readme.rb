require "danger/plugin_support/plugin_parser"
require "danger/plugin_support/plugin_file_resolver"
require "json"
require "erb"

module Danger
  class PluginReadme < CLAide::Command::Plugins
    self.summary = "Generates a README from a set of plugins"
    self.command = "readme"

    attr_accessor :cork, :json, :markdown

    def initialize(argv)
      @refs = argv.arguments! unless argv.arguments.empty?
      @cork = Cork::Board.new(silent: argv.option("silent", false),
                              verbose: argv.option("verbose", false))
      super
    end

    self.description = <<-DESC
      Converts a collection of file paths of Danger plugins into a format usable in a README.
      This is useful for Danger itself, but also for any plugins wanting to showcase their API.
    DESC

    self.arguments = [
      CLAide::Argument.new("Paths, Gems or Nothing", false, true)
    ]

    def run
      file_resolver = PluginFileResolver.new(@refs)
      data = file_resolver.resolve

      parser = PluginParser.new(data[:paths])
      parser.parse

      self.json = JSON.parse(parser.to_json_string)

      template = File.join(Danger.gem_path, "lib/danger/plugin_support/templates/readme_table.html.erb")
      cork.puts ERB.new(File.read(template), trim_mode: "-").result(binding)
    end
  end
end
