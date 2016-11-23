module Danger
  class GemsResolver
    def initialize(gem_names)
      @gem_names = gem_names
    end

    # returns Hash of paths and gems
    def call
      Bundler.with_clean_env do
        # We don't use the block syntax as we want it to persist until the OS cleans it on reboot
        # or whatever, it needs to persist outside this scope.
        dir = Dir.mktmpdir

        Dir.chdir(dir) do
          create_gemfile_from_gem_names
          `bundle install --path vendor/gems`

          return compute_under(dir), plugin_metadata_from_real_gems
        end
      end
    end

    private

    attr_reader :gem_names

    def create_gemfile_from_gem_names
      gemfile = File.new("Gemfile", "w")
      gemfile.write "source 'https://rubygems.org'"

      gem_names.each do |plugin|
        gemfile.write "\ngem '#{plugin}'"
      end

      gemfile.close
    end

    # The paths are relative to dir.
    def compute_under(dir)
      relative_paths = gem_names.flat_map do |plugin|
        Dir.glob("vendor/gems/ruby/*/gems/#{plugin}*/lib/**/**/**/**.rb")
      end

      relative_paths.map { |path| File.join(dir, path) }
    end

    def plugin_metadata_from_real_gems
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
