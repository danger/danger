module Danger
  class Violation
    attr_accessor :message, :sticky, :file, :line

    def initialize(message, sticky, file, line)
      self.message = message
      self.sticky = sticky
      self.file = file
      self.line = line
    end

    def to_s
      extra = []
      extra << "sticky: true" if sticky
      extra << "file: #{file}" unless file.nil?
      extra << "line: #{line}" unless line.nil?

      "Violation #{message} { #{extra.join ', '} }"
    end
  end
end
