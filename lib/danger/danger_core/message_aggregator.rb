# frozen_string_literal: true
require "danger/danger_core/message_group"
require "danger/helpers/message_groups_array_helper"

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
      @messages.sort! { |a, b| a.compare_by_file_and_line(b) }

      # now create an initial empty message group
      first_group = MessageGroup.new(file: nil,
                                     line: nil)
      @message_groups = @messages.reduce([first_group]) do |groups, msg|
        # We get to take a shortcut because we sorted the messages earlier - only
        # have to see if we can append msg to the last group in the list
        if groups.last << msg
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

      @message_groups.extend(Helpers::MessageGroupsArrayHelper)
    end
  end
end
