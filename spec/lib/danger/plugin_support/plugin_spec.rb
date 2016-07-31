describe Danger::Plugin do
  it 'creates an instance name based on the class name' do
    class DangerTestPlugin < Danger::Plugin; end
    expect(DangerTestPlugin.instance_name).to eq('test_plugin')
  end

  it 'should forward unknown method calls to the dangerfile' do
    class DangerTestPlugin < Danger::Plugin; end
    class DangerFileMock; attr_accessor :pants; end
    plugin = DangerTestPlugin.new(DangerFileMock.new)
    expect do
      plugin.pants
    end.to_not raise_error
  end
end
