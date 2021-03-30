# frozen_string_literal: true

require "danger/danger_core/messages/base"

module Danger
  class Violation < BaseMessage
    VALID_TYPES = %I[error warning message].freeze
    attr_accessor :sticky

    def initialize(message, sticky, file = nil, line = nil, type: :warning)
      raise ArgumentError unless VALID_TYPES.include?(type)

      super(type: type, message: message, file: file, line: line)
      self.sticky = sticky
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

    def <=>(other)
      types = VALID_TYPES + [:markdown]
      order = types.index(type) <=> types.index(other.type)
      return order unless order.zero?

      compare_by_file_and_line(other)
    end

    def to_s
      extra = []
      extra << "sticky: #{sticky}"
      extra << "file: #{file}" if file
      extra << "line: #{line}" if line
      extra << "type: #{type}"

      "Violation #{message} { #{extra.join ', '} }"
    end
  end
end
