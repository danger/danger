module Danger
  class Markdown
    attr_accessor :message, :file, :line

    def initialize(message, file, line)
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

    def inline?
      return (file.nil? && line.nil?) == false
    end

    def to_s
      extra = []
      extra << "file: #{file}" unless file.nil?
      extra << "line: #{line}" unless line.nil?

      "Markdown #{message} { #{extra.join ', '} }"
    end
  end
end
