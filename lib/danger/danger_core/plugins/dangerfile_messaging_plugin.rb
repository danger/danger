require 'danger/danger_core/violation'
require 'danger/plugin_support/plugin'

module Danger
  class DangerfileMessagingPlugin < Plugin
    def initialize(dangerfile)
      super(dangerfile)

      @warnings = []
      @errors = []
      @messages = []
      @markdowns = []
    end

    # @!group Core
    # Print markdown to below the table
    #
    # @param    [String] message
    #           The markdown based message to be printed below the table
    def markdown(message)
      @markdowns << message
      puts "Printing markdown #{message}"
    end

    # @!group Core
    # Print out a generate message on the PR
    #
    # @param    [String] message The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    def message(message, sticky: true)
      @messages << Violation.new(message, sticky)
      puts "Printing message '#{message}'"
    end

    # @!group Core
    # Specifies a problem, but not critical
    #
    # @param    [String] message The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    def warn(message, sticky: true)
      return if should_ignore_violation(message)
      @warnings << Violation.new(message, sticky)
      puts "Printing warning '#{message}'"
    end

    # @!group Core
    # Declares a CI blocking error
    #
    # @param    [String] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    def fail(message, sticky: true)
      return if should_ignore_violation(message)
      @errors << Violation.new(message, sticky)
      puts "Raising error '#{message}'"
    end

    def status_report
      {
        errors: @errors.map(&:message).clone.freeze,
        warnings: @warnings.map(&:message).clone.freeze,
        messages: @messages.map(&:message).clone.freeze,
        markdowns: @markdowns.map(&:message).clone.freeze
      }
    end

    def violation_report
      {
        errors: @errors.clone.freeze,
        warnings: @warnings.clone.freeze,
        messages: @messages.clone.freeze,
      }
    end

    private

    def should_ignore_violation(message)
      env.request_source.ignored_violations.include? message
    end
  end
end
