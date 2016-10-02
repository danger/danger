require "danger/commands/plugins/plugin_readme"

RSpec.describe Danger::PluginReadme do
  after do
    Danger::Plugin.clear_external_plugins
  end

  it "runs the command" do
    allow(STDOUT).to receive(:puts).with(fixture_txt("commands/plugin_md_example"))
    described_class.run(["spec/fixtures/plugins/example_fully_documented.rb"])
  end
end
