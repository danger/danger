require "danger/commands/plugins/plugin_gem"
require "securerandom"
require "rbconfig"

module Danger
  describe Danger::PluginGem, if: !(RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/) do
    let(:uuid) { SecureRandom.uuid.tr("-", "") }
    let(:gem_name) { "dangerfile-#{uuid}" }

    after do
      Plugin.clear_external_plugins
      FileUtils.rm_rf gem_name if Dir.exist?(gem_name)
    end

    it "creates a gem" do
      Danger::PluginGem.run([uuid])
      expect(Dir.exist?(gem_name)).to be true
      expect(File.exist?("#{gem_name}/Gemfile")).to be true
    end
  end
end
