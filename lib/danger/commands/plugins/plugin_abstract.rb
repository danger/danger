module Danger
  class PluginAbstract < Runner
    require 'danger/commands/plugins/plugin_lint'
    require 'danger/commands/plugins/new_plugin'

    self.command = 'plugin'

    self.abstract_command = true
  end
end
