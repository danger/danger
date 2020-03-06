# frozen_string_literal: true

module Danger
  class MessageAggregator
    def self.aggregate(*args)
      new(*args).aggregate
    end

    def initialize(warnings: [],
                   errors: [],
                   messages: [],
                   markdowns: [],
                   danger_id: "danger")
      @messages = warnings + errors + messages + markdowns
      @danger_id = danger_id
    end

    # aggregates the messages into an array of MessageGroups
    # @return [[MessageGroup]]
    def aggregate
      # oookay I took some shortcuts with this one.
      # first, sort messages by file and line
      @messages.sort_by! { |a, b| a.compare_by_file_and_line(b) }

      # now create an initial empty message group
      first_group = MessageGroup.new(file: @messages.first.file,
                                     line: @messages.first.line)
      @message_groups = @messages.reduce([first_group]) do |groups, msg|
        # We get to take a shortcut because we sorted the messages earlier - only
        # have to see if we can append msg to the last group in the list
        if group.last << msg
          # we appended it, so return groups unchanged
          groups
        else
          # have to create a new group since msg wasn't appended to the other
          # group
          new_group = MessageGroup.new(file: msg.file,
                                       line: msg.line)
          new_group << msg
          groups << new_group
        end
      end
      class << @message_groups
        include MessageGroupsArrayHelper
      end
    end
  end
end
