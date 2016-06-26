module Danger
  class PluginAbstract < Runner
    require 'danger/commands/plugin_lint'
    require 'danger/commands/new_plugin'

    self.command = 'plugin'

    self.abstract_command = true
  end
end
