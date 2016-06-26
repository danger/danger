require 'danger/commands/plugin_abstract'
require 'danger/plugin_support/plugin_parser'

module Danger
  class PluginLint < PluginAbstract
    self.summary = 'Lints a plugin'
    self.command = 'lint'

    def initialize(argv)
      @refs = argv.arguments! unless argv.arguments.empty?
      super
    end

    self.summary = 'Lint plugins from files, gems or the current folder. Outputs JSON array representation of Plugins on success.'

    self.description = <<-DESC
      Converts a collection of file paths of Danger plugins into a JSON format.
      Note: Before 1.0, it will also parse the represented JSON to validate whether http://danger.systems would
      show the plugin on the website.
    DESC

    self.arguments = [
      CLAide::Argument.new('Paths, Gems or Nothing', false, true)
    ]

    def run
      paths = nil

      # When given existing paths, map to absolute & existing paths
      if !@refs.nil? and @refs.select { |ref| File.file? ref }.any?
        paths = @refs.select { |ref| File.file? ref }
                     .map { |path| File.expand_path(path) }

      # When given a list of gems
      elsif @refs and @refs.kind_of? Array
        require 'bundler'
        require 'pathname'

        Dir.mktmpdir do |dir|
          gem_names = @refs
          deps = gem_names.map { |name| Bundler::Dependency.new(name, ">= 0") }

          # Use Gems from rubygems.org
          source = Bundler::SourceList.new
          source.add_rubygems_remote("https://rubygems.org")

          # Create a definition to bundle, make sure it always updates
          # and uses the latest version from the server
          bundler = Bundler::Definition.new(nil, deps, source, true)
          bundler.resolve_remotely!

          # Install the gems into a tmp dir
          options = { path: dir }
          Bundler::Installer.install(Pathname.new(dir), bundler, options)

          # Get the name'd gems out of bundler, then pull out all their paths
          gems = gem_names.map { |name| bundler.specs[name] }.flatten
          paths = gems.map { |gem| Dir.glob(File.join(gem.gem_dir, "lib/**/**/**.rb")) }.flatten
        end

      # When empty, imply you want to test the current lib folder as a plugin
      else
        paths = Dir.glob(File.join(".", "lib/*.rb"))
      end

      parser = PluginParser.new(paths)
      parser.parse
      json = parser.to_json
      cork.puts json
    end
  end
end
