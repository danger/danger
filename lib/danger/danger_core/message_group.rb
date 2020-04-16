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
      return nil unless same_line?(message)

      inserted = false
      messages.each.with_index do |other, idx|
        if (message <=> other) == -1
          inserted = true
          messages.insert(idx, message)
          break
        end
      end
      messages << message unless inserted
      messages
    end

    # The list of messages in this group. This list will be sorted in decreasing
    # order of severity (error, warning, message, markdown)
    def messages
      @messages ||= []
    end

    attr_reader :file, :line

    # @return a hash of statistics. Currently only :warnings_count and
    # :errors_count
    def stats
      stats = { warnings_count: 0, errors_count: 0 }
      messages.each do |msg|
        stats[:warnings_count] += 1 if msg.type == :warning
        stats[:errors_count] += 1 if msg.type == :error
      end
      stats
    end

    def markdowns
      messages.select { |x| x.type == :markdown }
    end
  end
end
