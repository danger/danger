module Danger
  class Violation
    attr_accessor :message, :sticky, :file, :line

    def initialize(message, sticky, file = nil, line = nil)
      self.message = message
      self.sticky = sticky
      self.file = file
      self.line = line
    end

    def ==(other)
      return false if other.nil?
      return false unless other.kind_of? self.class

      other.message == message &&
        other.sticky == sticky &&
        other.file == file &&
        other.line == line
    end

    # @return [Boolean] returns true if is a file or line, false otherwise
    def inline?
      file || line
    end

    def to_s
      extra = []
      extra << "sticky: #{sticky}"
      extra << "file: #{file}" if file
      extra << "line: #{line}" if line

      "Violation #{message} { #{extra.join ', '.freeze} }"
    end
  end
end
