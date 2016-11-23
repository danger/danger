require "danger/plugin_support/gems_resolver"

module Danger
  class PluginFileResolver
    # Takes an array of files, gems or nothing, then resolves them into
    # paths that should be sent into the documentation parser
    def initialize(references)
      @refs = references
    end

    # When given existing paths, map to absolute & existing paths
    # When given a list of gems, resolve for list of gems
    # When empty, imply you want to test the current lib folder as a plugin
    def resolve
      if !refs.nil? and refs.select { |ref| File.file? ref }.any?
        paths = refs.select { |ref| File.file? ref }.map { |path| File.expand_path(path) }
      elsif refs and refs.kind_of? Array
        paths, gems = GemsResolver.new(refs).call
      else
        paths = Dir.glob(File.join(".", "lib/**/*.rb")).map { |path| File.expand_path(path) }
      end

      { paths: paths, gems: gems || [] }
    end

    private

    attr_reader :refs
  end
end
