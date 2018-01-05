module Danger
  class Markdown
    attr_accessor :message, :file, :line

    def initialize(message, file = nil, line = nil)
      self.message = message
      self.file = file
      self.line = line
    end

    def ==(other)
      return false if other.nil?
      return false unless other.kind_of? self.class

      other.message == message &&
        other.file == file &&
        other.line == line
    end

    def hash
      h = 1
      h = h * 31 + message.hash
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
      extra << "file: #{file}" unless file
      extra << "line: #{line}" unless line

      "Markdown #{message} { #{extra.join ', '.freeze} }"
    end
  end
end
