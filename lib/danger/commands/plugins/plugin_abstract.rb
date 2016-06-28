module Danger
  class PluginAbstract < Runner
    require 'danger/commands/plugins/plugin_lint'
    require 'danger/commands/plugins/plugin_readme'
    require 'danger/commands/plugins/plugin_new'

    self.command = 'plugin'

    self.abstract_command = true
  end
end
