require "danger/version"
require "danger/dangerfile"

require 'claide'
require 'colored'

module Danger
  class DangerRunner < CLAide::Command

    self.description = 'Run the Dangerfile.'
    self.command = 'danger'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end


    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end

      Dangerfile.from_ruby @dangerfile_path
      puts "OK"
    end


    def run
      puts '* Boiling water…'
    end

  end
end
