require "bundler"

module Danger
  class GemsResolver
    def initialize(gem_names)
      @gem_names = gem_names
      @dir = Dir.mktmpdir # We want it to persist until OS cleans it on reboot
    end

    # Returns an Array of paths (plugin lib file paths) and gems (of metadata)
    def call
      path_gems = []

      Bundler.with_clean_env do
        Dir.chdir(dir) do
          create_gemfile_from_gem_names
          `bundle install --path vendor/gems`
          path_gems = all_gems_metadata
        end
      end

      return path_gems
    end

    private

    attr_reader :gem_names, :dir

    def all_gems_metadata
      return paths, gems
    end

    def create_gemfile_from_gem_names
      gemfile = File.new("Gemfile", "w")
      gemfile.write "source 'https://rubygems.org'"

      gem_names.each do |plugin|
        gemfile.write "\ngem '#{plugin}'"
      end

      gemfile.close
    end

    # The paths are relative to dir.
    def paths
      relative_paths = gem_names.flat_map do |plugin|
        Dir.glob("vendor/gems/ruby/*/gems/#{plugin}*/lib/**/**/**/**.rb")
      end

      relative_paths.map { |path| File.join(dir, path) }
    end

    def gems
      real_gems.map { |gem| gem_metadata(gem) }
    end

    def real_gems
      spec_paths = gem_names.flat_map do |plugin|
        Dir.glob("vendor/gems/ruby/*/specifications/#{plugin}*.gemspec").first
      end

      spec_paths.map { |path| Gem::Specification.load path }
    end

    def gem_metadata(gem)
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
  end
end
