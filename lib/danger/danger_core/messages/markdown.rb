module Danger
  class Markdown
    attr_accessor :message, :file, :line

    def initialize(message, file, line)
      self.message = message
      self.file = file
      self.line = line
    end

    def to_s
      extra = []
      extra << "file: #{file}" unless file.nil?
      extra << "line: #{line}" unless line.nil?

      "Markdown #{message} { #{extra.join ', '} }"
    end
  end
end
