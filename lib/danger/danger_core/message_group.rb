# frozen_string_literal: true

module Danger
  class MessageGroup
    def initialize(file: nil, line: nil)
      @file = file
      @line = line
    end

    # Returns whether this `MessageGroup` is for the same line of code as
    #   `other`, taking which file they are in to account.
    # @param other [MessageGroup, Markdown, Violation]
    # @return [Boolean] whether this `MessageGroup` is for the same line of code
    def same_line?(other)
      other.file == file && other.line == line
    end

    # Merges two `MessageGroup`s that represent the same line of code
    # In future, perhaps `MessageGroup` will be able to represent a group of
    # messages for multiple lines.
    def merge(other)
      raise ArgumentError, "Cannot merge with MessageGroup for a different line" unless same_line?(other)

      @messages = (messages + other.messages).uniq
    end

    # Adds a message to the group.
    # @param message [Markdown, Violation] the message to add
    def <<(message)
      # TODO: insertion sort
      messages << message if same_line?(message)
    end

    # The list of messages in this group. This list will be sorted in decreasing
    # order of severity (error, warning, message, markdown)
    def messages
      @messages ||= []
    end

    attr_reader :file, :line
  end
end
