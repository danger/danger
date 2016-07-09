require "danger/commands/plugins/plugin_lint"

module Danger
  describe Danger::PluginLint do
    after do
      Plugin.clear_external_plugins
    end

    it "runs the command" do
      # allow(STDOUT).to receive(:puts) # this disables puts
      Danger::PluginLint.run(["spec/fixtures/plugins/example_fully_documented.rb"])
    end
  end
end
