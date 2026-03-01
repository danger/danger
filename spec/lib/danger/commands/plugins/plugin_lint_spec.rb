require "danger/commands/plugins/plugin_lint"

RSpec.describe Danger::PluginLint do
  after do
    Danger::Plugin.clear_external_plugins
  end

  it "runs the command" do
    allow(STDOUT).to receive(:puts)
    described_class.run(["spec/fixtures/plugins/example_fully_documented.rb"])
  end
end
