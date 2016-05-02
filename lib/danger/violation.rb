module Danger
  class Violation
    attr_accessor :message, :sticky

    def initialize(message, sticky)
      self.message = message
      self.sticky = sticky
    end
  end
end
