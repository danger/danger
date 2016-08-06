require "danger/danger_core/plugins/dangerfile_messaging_plugin"
require "danger/danger_core/plugins/dangerfile_import_plugin"
require "danger/danger_core/plugins/dangerfile_git_plugin"
require "danger/danger_core/plugins/dangerfile_github_plugin"

require "danger/danger_core/plugin_printer"

module Danger
  # This class holds all the curent plugin instances, and is
  # resonsible for keeping track of ones the Dangerfiles should care about.
  #
  class PluginHost
    # Plugins whose methods/attributes are unscoped.
    attr_accessor :core_plugins

    # Plugins whose methods/attributes are scoped via the `instance_name`.
    attr_accessor :external_plugins

    # All plugins
    attr_accessor :plugins

    # These are the classes that are allowed to also use method_missing
    # in order to provide broader plugin support
    def self.core_plugin_classes
      [DangerfileMessagingPlugin]
    end

    # The ones that everything would break without
    def self.essential_plugin_classes
      [DangerfileMessagingPlugin, DangerfileGitPlugin, DangerfileImportPlugin, DangerfileGitHubPlugin]
    end

    def initialize
      super

      self.plugins = {}
      self.core_plugins = []
      self.external_plugins = []

      # Triggers local plugins from the root of a project
      Dir["./danger_plugins/*.rb"].each do |file|
        require File.expand_path(file)
      end
    end

    # A trigger that there may be new plugins loaded inside the runtime
    def refresh_plugins(dangerfile)
      all_plugins = Plugin.all_plugins
      all_plugins.each do |klass|
        next if klass.respond_to?(:singleton_class?) && klass.singleton_class?

        # Generate an instance
        plugin = klass.new(dangerfile)
        next if plugin.nil? || plugins[klass]

        # Keep track of it
        plugins[klass] = plugin

        # Move it into the right plugin array
        is_core = self.class.core_plugin_classes.include? klass
        bucket = is_core ? core_plugins : external_plugins
        bucket << plugin
      end
    end
    alias init_plugins refresh_plugins

    def printer
      PluginPrinter.new(self)
    end
  end
end
