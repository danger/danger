require "danger/commands/plugins/plugin_json"

module Danger
  describe Danger::PluginJSON do
    after do
      Plugin.clear_external_plugins
    end

    it "runs the command" do
      Danger::PluginJSON.run(["spec/fixtures/plugins/example_fully_documented.rb"])
    end
  end
end
