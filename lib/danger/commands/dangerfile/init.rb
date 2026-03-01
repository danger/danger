require "danger/danger_core/dangerfile_generator"

# Mainly so we can have a nice strucutre for commands

module Danger
  class DangerfileCommand < Runner
    self.summary = "Easily create you Dangerfiles."
    self.command = "dangerfile"

    self.abstract_command = true
    def self.options
      []
    end
  end
end

# Just a less verbose way of doing the Dangerfile from `danger init`.

module Danger
  class DangerfileInit < DangerfileCommand
    self.summary = "Create an example Dangerfile."
    self.command = "init"

    def run
      content = DangerfileGenerator.create_dangerfile(".", cork)
      File.write("Dangerfile", content)
      cork.puts "Created" + "./Dangerfile".green
    end
  end
end
