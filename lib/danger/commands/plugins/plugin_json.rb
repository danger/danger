require "danger/plugin_support/plugin_parser"
require "danger/plugin_support/plugin_file_resolver"

module Danger
  class PluginJSON < CLAide::Command::Plugins
    self.summary = "Prints the JSON documentation representing a plugin"
    self.command = "json"

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
    DESC

    self.arguments = [
      CLAide::Argument.new("Paths, Gems or Nothing", false, true)
    ]

    def run
      file_resolver = PluginFileResolver.new(@refs)
      data = file_resolver.resolve

      parser = PluginParser.new(data[:paths])
      parser.parse
      json = parser.to_json

      # Append gem metadata into every plugin
      data[:gems].each do |gem_data|
        json.each do |plugin|
          plugin[:gem_metadata] = gem_data if plugin[:gem] == gem_data[:gem]
        end
      end

      cork.puts json.to_json
    end
  end
end
