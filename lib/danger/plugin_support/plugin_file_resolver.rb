require 'bundler'
require 'pathname'
require 'fileutils'

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
          # We don't use the block syntax as we want it to persist until the OS cleans it on reboot
          # or whatever, it needs to persist outside this scope.
          dir = Dir.mktmpdir

          Dir.chdir(dir) do
            gem_names = @refs
            gemfile = File.new('Gemfile', 'w')
            gemfile.write "source 'https://rubygems.org'"

            gem_names.each do |plugin|
              gemfile.write "\ngem '#{plugin}'"
            end

            gemfile.close
            `bundle install --path vendor/gems`

            # the paths are relative to our current Chdir
            relative_paths = gem_names.flat_map { |plugin| Dir.glob("vendor/gems/ruby/*/gems/#{plugin}*/lib/**/**/**/**.rb") }
            relative_paths.map { |path| File.join(dir, path) }
          end
        end
      # When empty, imply you want to test the current lib folder as a plugin
      else
        Dir.glob(File.join('.', 'lib/**/*.rb')).map { |path| File.expand_path(path) }
      end
    end
  end
end
