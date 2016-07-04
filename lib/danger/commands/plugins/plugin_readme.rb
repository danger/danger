require 'danger/commands/plugins/plugin_abstract'
require 'danger/plugin_support/plugin_parser'
require 'danger/plugin_support/plugin_file_resolver'
require 'json'

module Danger
  class PluginReadme < PluginAbstract
    self.summary = 'Generates a README from a set of plugins'
    self.command = 'readme'

    def initialize(argv)
      @refs = argv.arguments! unless argv.arguments.empty?
      super
    end

    self.summary = 'Lint plugins from files, gems or the current folder. Outputs JSON array representation of Plugins on success.'

    self.description = <<-DESC
      Converts a collection of file paths of Danger plugins into a format usable in a README.
      This is useful for Danger itself, but also for any plugins wanting to showcase their API.
    DESC

    self.arguments = [
      CLAide::Argument.new('Paths, Gems or Nothing', false, true)
    ]

    attr_accessor :json, :markdown
    def run
      file_resolver = PluginFileResolver.new(@refs)
      paths = file_resolver.resolve_to_paths

      parser = PluginParser.new(paths)
      parser.parse

      self.markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_intra_emphasis: true)
      self.json = JSON.parse(parser.to_json)

      template = File.join(Danger.gem_path, 'lib/danger/plugin_support/templates/readme_table.html.erb')
      cork.puts ERB.new(File.read(template), 0, '-').result(binding)
    end
  end
end
