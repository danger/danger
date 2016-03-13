require 'danger/plugin_manager'

describe Danger::PluginManager do
  before do
    @manager = Danger::PluginManager
    @manager.instance_variable_set(:@registrations, nil)
  end

  describe 'register' do
    it 'allows to register a block for a notification with a given name' do
      @manager.register('plugin') {}
      expect(@manager.registrations.count).to eq(1)

      plugin = @manager.registrations.first
      expect(plugin.class).to eq(Danger::PluginManager::Plugin)
      expect(plugin.name).to eq("plugin")
    end

    describe 'run' do
      it 'invokes the plugins' do
        @manager.register('plugin') do |_options|
          expect(true).to eq(true)
        end
        @manager.run(Object.new)
      end

      it 'passes along user-specified options when the hook block has arity 2' do
        @manager.register('plugin') do |_options, user_options|
          expect(user_options['key']).to eq('value')
        end

        expect do
          @manager.run(Object.new, 'plugin' => { 'key' => 'value' })
        end.to_not raise_error
      end

      it 'only runs hooks from the allowed plugins' do
        @manager.register('plugin') do |_options|
          raise 'Should not be called'
        end
        expect do
          @manager.run(Object.new, 'plugin2' => {})
        end.to_not raise_error
      end

      #
      #
      # it 'passes along user-specified options as hashes with indifferent access' do
      #   run_count = 0
      #   @hooks_manager.register('plugin', :post_install) do |_options, user_options|
      #     user_options['key'].should == 'value'
      #     user_options[:key].should == 'value'
      #     run_count += 1
      #   end
      #
      #   @hooks_manager.run(:post_install, Object.new, 'plugin' => { 'key' => 'value' })
      #   @hooks_manager.run(:post_install, Object.new, 'plugin' => { :key => 'value' })
      #   run_count.should == 2
      # end
      #
    end
  end
end
