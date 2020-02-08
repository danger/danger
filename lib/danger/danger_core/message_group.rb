module Danger
  class MessageGroup
    def initialize(file: nil, line: nil)
      @file = file
      @line = line
    end

    def same_line?(other)
      other.file == file && other.line == line
    end

    def merge(other)
      raise ArgumentError, "Cannot merge with MessageGroup for a different line" unless same_line?(other)
      @messages = (messages + other.messages).uniq
    end

    def <<(message)
      # TODO: insertion sort
      messages << message if same_line?(message)
    end

    def messages
      @messages ||= []
    end

    attr_reader :file, :line
  end
end
