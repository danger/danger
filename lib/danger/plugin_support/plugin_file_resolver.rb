require "bundler"
require "pathname"
require "fileutils"

module Danger
  class PluginFileResolver
    # Takes an array of files, gems or nothing, then resolves them into
    # paths that should be sent into the documentation parser
    def initialize(references)
      @refs = references
    end

    def resolve
      # When given existing paths, map to absolute & existing paths
      if !@refs.nil? and @refs.select { |ref| File.file? ref }.any?
        paths = @refs.select { |ref| File.file? ref }.map { |path| File.expand_path(path) }
        { paths: paths, gems: [] }

      # When given a list of gems
      elsif @refs and @refs.kind_of? Array
        Bundler.with_clean_env do
          # We don't use the block syntax as we want it to persist until the OS cleans it on reboot
          # or whatever, it needs to persist outside this scope.
          dir = Dir.mktmpdir

          Dir.chdir(dir) do
            gem_names = @refs
            gemfile = File.new("Gemfile", "w")
            gemfile.write "source 'https://rubygems.org'"

            gem_names.each do |plugin|
              gemfile.write "\ngem '#{plugin}'"
            end

            gemfile.close
            `bundle install --path vendor/gems`

            # the paths are relative to our current Chdir
            relative_paths = gem_names.flat_map { |plugin| Dir.glob("vendor/gems/ruby/*/gems/#{plugin}*/lib/**/**/**/**.rb") }
            paths = relative_paths.map { |path| File.join(dir, path) }

            spec_paths = gem_names.flat_map { |plugin| Dir.glob("vendor/gems/ruby/*/specifications/#{plugin}*.gemspec").first }
            real_gems = spec_paths.map { |path| Gem::Specification.load path }

            plugin_metadata = real_gems.map do |gem|
              {
                name: gem.name,
                gem: gem.name,
                author: gem.authors,
                url: gem.homepage,
                description: gem.summary,
                license: gem.license || "Unknown",
                version: gem.version.to_s
              }
            end
            { paths: paths, gems: plugin_metadata }
          end
        end
      # When empty, imply you want to test the current lib folder as a plugin
      else
        paths = Dir.glob(File.join(".", "lib/**/*.rb")).map { |path| File.expand_path(path) }
        { paths: paths, gems: [] }
      end
    end
  end
end
