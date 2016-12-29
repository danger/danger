require "lib/danger/plugin_support/gems_resolver"

RSpec.describe Danger::GemsResolver do
  def expected_path(dir)
    [
      "#{dir}/vendor/gems/ruby/2.3.0/gems/danger-rubocop-0.3.0/lib/danger_plugin.rb",
      "#{dir}/vendor/gems/ruby/2.3.0/gems/danger-rubocop-0.3.0/lib/version.rb"
    ]
  end

  def expected_gems
    [
      {
        name: "danger-rubocop",
        gem: "danger-rubocop",
        author: ["Ash Furrow"],
        url: "https://github.com/ashfurrow/danger-rubocop",
        description: "A Danger plugin for running Ruby files through Rubocop.",
        license: "MIT",
        version: "0.3.0"
      }
    ]
  end

  # Mimic bundle install --path vendor/gems when install danger-rubocop
  def fake_bundle_install_path_vendor_gems_in(spec_root)
    FileUtils.mkdir_p("vendor/gems/ruby/2.3.0/gems/danger-rubocop-0.3.0/lib")
    FileUtils.touch("vendor/gems/ruby/2.3.0/gems/danger-rubocop-0.3.0/lib/version.rb")
    FileUtils.touch("vendor/gems/ruby/2.3.0/gems/danger-rubocop-0.3.0/lib/danger_plugin.rb")

    FileUtils.mkdir_p("vendor/gems/ruby/2.3.0/specifications")
    FileUtils.cp(
      "#{spec_root}/spec/fixtures/gemspecs/danger-rubocop.gemspec",
      "vendor/gems/ruby/2.3.0/specifications/danger-rubocop-0.3.0.gemspec"
    )
  end

  describe "#call" do
    it "create gemfile, bundle, and returns" do
      spec_root = Dir.pwd
      gem_names = ["danger-rubocop"]
      tmpdir = Dir.mktmpdir

      # We want to control the temp dir created in gems_resolver
      # to compare in our test
      allow(Dir).to receive(:mktmpdir) { tmpdir }

      Dir.chdir(tmpdir) do
        expect(Bundler).to receive(:with_clean_env) do
          fake_bundle_install_path_vendor_gems_in(spec_root)
        end

        resolver = described_class.new(gem_names)
        resolver.call
        result = resolver.send(:all_gems_metadata)

        expect(result).to be_a Array
        expect(result.first).to match_array expected_path(tmpdir)
        expect(result.last).to match_array expected_gems
      end
    end
  end
end
