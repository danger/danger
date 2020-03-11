require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"
require "danger/plugin_support/plugin"

module Danger
  # Provides the feedback mechanism for Danger. Danger can keep track of
  # messages, warnings, failure and post arbitrary markdown into a comment.
  #
  # The message within which Danger communicates back is amended on each run in a session.
  #
  # Each of `message`, `warn` and `fail` have a `sticky` flag, `false` by default, which
  # when `true` means that the message will be crossed out instead of being removed.
  # If it's not called again on subsequent runs.
  #
  # Each of `message`, `warn`, `fail` and `markdown` support multiple passed arguments
  # @example
  #
  # message 'Hello', 'World', file: "Dangerfile", line: 1
  # warn ['This', 'is', 'warning'], file: "Dangerfile", line: 1
  # failure 'Ooops', 'bad bad error', sticky: false
  # markdown '# And', '# Even', '# Markdown', file: "Dangerfile", line: 1
  #
  # By default, using `failure` would fail the corresponding build. Either via an API call, or
  # via the return value for the danger command. Older code examples use `fail` which is an alias
  # of `failure`, but the default Rubocop settings would have an issue with it.
  #
  # You can optionally add `file` and `line` to provide inline feedback on a PR in GitHub, note that
  # only feedback inside the PR's diff will show up inline. Others will appear inside the main comment.
  #
  # It is possible to have Danger ignore specific warnings or errors by writing `Danger: Ignore "[warning/error text]"`.
  #
  # Sidenote: Messaging is the only plugin which adds functions to the root of the Dangerfile.
  #
  # @example Failing a build
  #
  #          failure "This build didn't pass tests"
  #          failure "Ooops!", "Something bad happened"
  #          failure ["This is example", "with array"]
  #
  # @example Failing a build, and note that on subsequent runs
  #
  #          failure("This build didn't pass tests", sticky: true)
  #
  # @example Passing a warning
  #
  #          warn "This build didn't pass linting"
  #          warn "Hm...", "This is not really good"
  #          warn ["Multiple warnings", "via array"]
  #
  # @example Displaying a markdown table
  #
  #          message = "### Proselint found issues\n\n"
  #          message << "Line | Message | Severity |\n"
  #          message << "| --- | ----- | ----- |\n"
  #          message << "20 | No documentation | Error \n"
  #          markdown message
  #
  #          markdown "### First issue", "### Second issue"
  #          markdown ["### First issue", "### Second issue"]
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
    # @param    [String, Array<String>] message
    #           The markdown based message to be printed below the table
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def markdown(*markdowns, **options)
      file = options.fetch(:file, nil)
      line = options.fetch(:line, nil)

      markdowns.flatten.each do |markdown|
        @markdowns << Markdown.new(markdown, file, line)
      end
    end

    # @!group Core
    # Print out a generate message on the PR
    #
    # @param    [String, Array<String>] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `false`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def message(*messages, **options)
      sticky = options.fetch(:sticky, false)
      file = options.fetch(:file, nil)
      line = options.fetch(:line, nil)

      messages.flatten.each do |message|
        @messages << Violation.new(message, sticky, file, line, type: :message) if message
      end
    end

    # @!group Core
    # Specifies a problem, but not critical
    #
    # @param    [String, Array<String>] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `false`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def warn(*warnings, **options)
      sticky = options.fetch(:sticky, false)
      file = options.fetch(:file, nil)
      line = options.fetch(:line, nil)

      warnings.flatten.each do |warning|
        next if should_ignore_violation(warning)
        @warnings << Violation.new(warning, sticky, file, line, type: :warning) if warning
      end
    end

    # @!group Core
    # Declares a CI blocking error
    #
    # @param    [String, Array<String>] message
    #           The message to present to the user
    # @param    [Boolean] sticky
    #           Whether the message should be kept after it was fixed,
    #           defaults to `false`.
    # @param    [String] file
    #           Optional. Path to the file that the message is for.
    # @param    [String] line
    #           Optional. The line in the file to present the message in.
    # @return   [void]
    #
    def fail(*failures, **options)
      sticky = options.fetch(:sticky, false)
      file = options.fetch(:file, nil)
      line = options.fetch(:line, nil)

      failures.flatten.each do |failure|
        next if should_ignore_violation(failure)
        @errors << Violation.new(failure, sticky, file, line, type: :error) if failure
      end
    end

    alias_method :failure, :fail

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
