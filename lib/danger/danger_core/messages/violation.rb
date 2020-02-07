module Danger
  class Violation
    VALID_TYPES = %I[error warning message]
    attr_accessor :message, :sticky, :file, :line, :type

    def initialize(message, sticky, file = nil, line = nil, type: :warning)
      self.message = message
      self.sticky = sticky
      self.file = file
      self.line = line
      raise ArgumentError unless VALID_TYPES.include?(type)
      self.type = type
    end

    def ==(other)
      return false if other.nil?
      return false unless other.kind_of? self.class

      other.message == message &&
        other.sticky == sticky &&
        other.file == file &&
        other.line == line
    end

    def hash
      h = 1
      h = h * 31 + message.hash
      h = h * 13 + sticky.hash
      h = h * 17 + file.hash
      h = h * 17 + line.hash
      h
    end

    def eql?(other)
      return self == other
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
      extra << "type: #{type}"

      "Violation #{message} { #{extra.join ', '.freeze} }"
    end
  end
end
