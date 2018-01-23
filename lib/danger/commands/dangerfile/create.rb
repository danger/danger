module Danger
  class Dangerfile < Runner
    self.abstract_command = true
    self.description = "Commands related to the Dangerfile."
    self.summary = self.description
  end

  class DangerfileCreate < Dangerfile
    self.command = "create"
    self.summary = "Create a new gem-based Dangerfile."

    def run
      CLAide
    end
  end
end
