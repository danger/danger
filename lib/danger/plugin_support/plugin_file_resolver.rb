require 'bundler'
require 'pathname'

module Danger
  class PluginFileResolver
    # Takes an array of files, gems or nothing, then resolves them into
    # paths that should be sent into the documentation parser
    def initialize(references)
      @refs = references
    end

    def resolve_to_paths
      # When given existing paths, map to absolute & existing paths
      if !@refs.nil? and @refs.select { |ref| File.file? ref }.any?
        @refs.select { |ref| File.file? ref }.map { |path| File.expand_path(path) }

      # When given a list of gems
      elsif @refs and @refs.kind_of? Array
        Bundler.with_clean_env do
          Dir.mktmpdir do |dir|
            gem_names = @refs
            deps = gem_names.map { |name| Bundler::Dependency.new(name, '>= 0') }

            # Use Gems from rubygems.org
            source = Bundler::SourceList.new
            source.add_rubygems_remote('https://rubygems.org')

            # Create a definition to bundle, make sure it always updates
            # and uses the latest version from the server
            bundler = Bundler::Definition.new(nil, deps, source, true)
            bundler.resolve_remotely!

            # Install the gems into a tmp dir
            options = { path: dir }
            Bundler::Installer.install(Pathname.new(dir), bundler, options)

            # Get the name'd gems out of bundler, then pull out all their paths
            gems = gem_names.flat_map { |name| bundler.specs[name] }
            gems.flat_map { |gem| Dir.glob(File.join(gem.gem_dir, 'lib/**/**/**.rb')) }
          end
        end
      # When empty, imply you want to test the current lib folder as a plugin
      else
        Dir.glob(File.join('.', 'lib/*.rb')).map { |path| File.expand_path(path) }
      end
    end
  end
end
