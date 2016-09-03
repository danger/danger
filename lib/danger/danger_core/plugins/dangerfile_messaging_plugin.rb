require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"
require "danger/plugin_support/plugin"

module Danger
  # Provides the feedback mechanism for Danger. Danger can keep track of
  # messages, warnings, failure and post arbitrary markdown into a comment.
  #
  # The message within which Danger communicates back is amended on each run in a session.
  #
  # Each of `message`, `warn` and `fail` have a `sticky` flag, `true` by default, which
  # means that the message will be crossed out instead of being removed. If it's not use on
  # subsequent runs.
  #
  # By default, using `fail` would fail the corresponding build. Either via an API call, or
  # via the return value for the danger command.
  #
  # It is possible to have Danger ignore specific warnings or errors by writing `Danger: Ignore "[warning/error text]`.
  #
  # Sidenote: Messaging is the only plugin which adds functions to the root of the Dangerfile.
  #
  # @example Failing a build
  #
  #          fail "This build didn't pass tests"
  #
  # @example Failing a build, but not keeping its value around on subsequent runs
  #
  #          fail("This build didn't pass tests", sticky: false)
  #
  # @example Passing a warning
  #
  #          warn "This build didn't pass linting"
  #
  # @example Displaying a markdown table
  #
  #          message = "### Proselint found issues\n\n"
  #          message << "Line | Message | Severity |\n"
  #          message << "| --- | ----- | ----- |\n"
  #          message << "20 | No documentation | Error \n"
  #          markdown message
  #
  # @example Adding an inline warning to a file
  #
  #          warn("You shouldn't use puts in your Dangerfile", file: "Dangerfile", line: 10)
  #
  #
  # @see  danger/danger
  # @tags core, messaging
  #

  class DangerfileMessagingPlugin < Plugin
    def initialize(dangerfile)
      super(dangerfile)

      @warnings = []
      @errors = []
      @messages = []
      @markdowns = []
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "messaging"
    end

    # @!group Core
    # Print markdown to below the table
    #
    # @param    [String] message
    #           The markdown based message to be printed below the table
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def markdown(message, file: nil, line: nil)
      @markdowns << Markdown.new(message, file, line)
    end

    # @!group Core
    # Print out a generate message on the PR
    #
    # @param    [String] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def message(message, sticky: true, file: nil, line: nil)
      @messages << Violation.new(message, sticky, file, line)
    end

    # @!group Core
    # Specifies a problem, but not critical
    #
    # @param    [String] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def warn(message, sticky: true, file: nil, line: nil)
      return if should_ignore_violation(message)
      @warnings << Violation.new(message, sticky, file, line)
    end

    # @!group Core
    # Declares a CI blocking error
    #
    # @param    [String] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `true`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def fail(message, sticky: true, file: nil, line: nil)
      return if should_ignore_violation(message)
      @errors << Violation.new(message, sticky, file, line)
    end

    # @!group Reporting
    # A list of all messages passed to Danger, including
    # the markdowns.
    #
    # @visibility hidden
    # @return     [Hash]
    def status_report
      {
        errors: @errors.map(&:message).clone.freeze,
        warnings: @warnings.map(&:message).clone.freeze,
        messages: @messages.map(&:message).clone.freeze,
        markdowns: @markdowns.clone.freeze
      }
    end

    # @!group Reporting
    # A list of all violations passed to Danger, we don't
    # anticipate users of Danger needing to use this.
    #
    # @visibility hidden
    # @return     [Hash]
    def violation_report
      {
        errors: @errors.clone.freeze,
        warnings: @warnings.clone.freeze,
        messages: @messages.clone.freeze
      }
    end

    private

    def should_ignore_violation(message)
      env.request_source.ignored_violations.include? message
    end
  end
end
