require "danger/danger_core/plugin_host"

describe Danger::PluginHost, host: :github do
  it "should add a plugin to the dangerfile plugins array" do
    Danger::Plugin.clear_external_plugins

    class DangerHostTestPlugin < Danger::Plugin; end
    allow(Danger::Plugin).to receive(:all_plugins).and_return([DangerHostTestPlugin])

    dm = testing_dangerfile
    expect(dm.plugins.map(&:class)).to include(DangerHostTestPlugin)
  end

  it "should have the DangerfileMessagingPlugin as a core plugin" do
    subject = Danger::PluginHost.new
    subject.refresh_plugins(testing_dangerfile)

    expect(subject.core_plugins.map(&:class)).to include(Danger::DangerfileMessagingPlugin)
  end
end
