# frozen_string_literal: true
require "danger/danger_core/messages/base"

module Danger
  class Markdown < BaseMessage

    def initialize(message, file = nil, line = nil)
      super(type: :markdown, message: message, file: file, line: line)
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

    def to_s
      extra = []
      extra << "file: #{file}" unless file
      extra << "line: #{line}" unless line

      "Markdown #{message} { #{extra.join ', '.freeze} }"
    end

    def <=>(other)
      return 1 if other.type != :markdown

      compare_by_file_and_line(other)
    end
  end
end
