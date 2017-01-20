RSpec.describe Danger::Plugin do
  it "creates an instance name based on the class name" do
    class DangerTestClassNamePlugin < Danger::Plugin; end
    expect(DangerTestClassNamePlugin.instance_name).to eq("test_class_name_plugin")
  end

  it "should forward unknown method calls to the dangerfile" do
    class DangerTestForwardPlugin < Danger::Plugin; end
    class DangerFileMock; attr_accessor :pants; end

    plugin = DangerTestForwardPlugin.new(DangerFileMock.new)
    expect do
      plugin.pants
    end.to_not raise_error
  end
end
