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
          expect(user_options[:key]).to eq('value')
        end

        expect do
          @manager.run(Object.new, 'plugin' => { key: 'value' })
        end.to_not raise_error
      end

      it 'runs when block has arity 1' do
        @manager.register('plugin') do |_options|
          expect("yer a plugin harry").to eq("yer a wizard harry")
        end

        expect do
          @manager.run(Object.new, 'plugin' => { key: 'value' })
        end.to raise_error
      end

      it 'only runs hooks from the allowed plugins' do
        @manager.register('plugin') do |_options|
          raise 'Should not be called'
        end
        expect do
          @manager.run(Object.new, 'plugin2' => {})
        end.to_not raise_error
      end

      it 'passes along user-specified options as symbol hashes only' do
        sym_count = 0
        string_count = 0
        @manager.register('plugin') do |_options, user_options|
          string_count += 1 if user_options['key']
          sym_count += 1 if user_options[:key]
        end

        @manager.run(Object.new, 'plugin' => { 'key' => 'value' })
        @manager.run(Object.new, 'plugin' => { key: 'value' })

        expect(sym_count).to eq(2)
        expect(string_count).to eq(0)
      end
    end
  end
end
