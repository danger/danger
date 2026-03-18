# frozen_string_literal: true

require "danger/danger_core/messages/base"

module Danger
  class Markdown < BaseMessage
    VALID_SIDES = %w(LEFT RIGHT).freeze

    def initialize(message, file = nil, line = nil, start_line: nil, side: nil, start_side: nil)
      validate_side!(:side, side)
      validate_side!(:start_side, start_side)

      super(
        type: :markdown,
        message: message,
        file: file,
        line: line,
        start_line: start_line,
        side: side,
        start_side: start_side
      )
    end

    def ==(other)
      return false if other.nil?
      return false unless other.kind_of? self.class

      other.message == message &&
        other.file == file &&
        other.line == line &&
        other.start_line == start_line &&
        other.side == side &&
        other.start_side == start_side
    end

    def hash
      h = 1
      h = h * 31 + message.hash
      h = h * 17 + file.hash
      h = h * 17 + line.hash
      h = h * 17 + start_line.hash
      h = h * 17 + side.hash
      h * 17 + start_side.hash
    end

    def to_s
      extra = []
      extra << "file: #{file}" if file
      extra << "line: #{line}" if line
      extra << "start_line: #{start_line}" if start_line
      extra << "side: #{side}" if side
      extra << "start_side: #{start_side}" if start_side

      "Markdown #{message} { #{extra.join ', '} }"
    end

    def <=>(other)
      return 1 if other.type != :markdown

      compare_by_file_and_line(other)
    end

    private

    def validate_side!(name, value)
      return if value.nil? || VALID_SIDES.include?(value)

      raise ArgumentError, "#{name} must be LEFT or RIGHT"
    end
  end
end
