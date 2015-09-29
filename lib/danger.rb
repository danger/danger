require "danger/version"

require 'claide'
require 'colored'

module Danger
  class DangerRunner < CLAide::Command

    self.description = 'Run the Dangerfile.'
    self.command = 'danger'

    def run
      puts '* Boiling water…'
    end

  end
end
