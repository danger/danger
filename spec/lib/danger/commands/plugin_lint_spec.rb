require 'danger/commands/plugin_lint'

module Danger
  describe Danger::PluginLint do
    it "runs the command" do
      # allow(STDOUT).to receive(:puts) # this disables puts
      Danger::PluginLint.run(["lib/spec/fixtures/plugins/example_fully_documented.rb"])
    end
  end
end



