require "danger/commands/plugins/plugin_json"

RSpec.describe Danger::PluginJSON do
  after do
    Danger::Plugin.clear_external_plugins
  end

  it "runs the command" do
    described_class.run(["spec/fixtures/plugins/example_fully_documented.rb"])
  end
end
