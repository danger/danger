## This is very strongly inspired by the plugin system provided by CocoaPods
## under the MIT license at: https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/hooks_manager.rb

module Danger
  # Provides support for the Plugin system of Danger. The system is designed
  # especially for plugins. Interested clients can register to notifications by
  # name.
  #
  # The blocks, to prevent compatibility issues, will receive
  # one and only one argument: a context object. This object should be simple
  # storage of information (a typed hash). Notifications senders are
  # responsible to indicate the class of the object associated with their
  # notification name.
  #
  module PluginManager
    # Represents a single registered plugin.
    #
    class Plugin
      # @return [String]
      #         The name of the plugin.
      #
      attr_reader :name

      # @return [Proc]
      #         The block.
      #
      attr_reader :block

      # Initialize a new instance
      #
      # @param  [String] name        @see {#name}.
      #
      # @param  [Proc]   block       @see {#block}.
      #
      def initialize(name, block)
        raise ArgumentError, 'Missing name' unless name
        raise ArgumentError, 'Missing block' unless block

        @name = name
        @block = block
      end
    end

    class << self
      # @return [Array<Plugin>] The list of the registered plugins
      #
      attr_reader :registrations

      # Registers a block for the plugin with the given name.
      #
      # @param  [String] name
      #         The name of the plugin
      #
      # @param  [Proc] block
      #         The block.
      #
      def register(name, &block)
        @registrations ||= []
        @registrations << Plugin.new(name, block)
      end

      # Runs all the registered blocks for the plugin with the given name.
      #
      # @param  [Object] context
      #         The context object which should be passed to the blocks.
      #
      # @param  [Hash<Symbol, Hash>] whitelisted_plugins
      #         The plugins that should be run, in the form of a hash keyed by
      #         plugin name, where the values are the custom options that should
      #         be passed to the plugin's block if it supports taking a second
      #         argument. Keys are always symbols.
      #
      def run(context, whitelisted_plugins = nil)
        raise ArgumentError, 'Missing options' unless context

        unless registrations.empty?
          puts "- Running Plugins"
          registrations.each do |plugin|
            next if whitelisted_plugins && !whitelisted_plugins.key?(plugin.name)
            puts "- #{plugin.name} from `#{plugin.block.source_location.first}`"
            block = plugin.block

            if block.arity > 1
              user_options = whitelisted_plugins ? whitelisted_plugins[plugin.name] : {}
              block.call(context, symbolize_hash(user_options))
            else
              block.call(context)
            end
          end
        end
      end

      # http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash#800498
      def symbolize_hash(obj)
        new_hash = {}
        obj.each { |k, v| new_hash[k.to_sym] = v }
        new_hash
      end
    end
  end
end
