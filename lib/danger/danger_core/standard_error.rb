require "claide"
require "claide/informative_error"

module Danger
  # From below here - this entire file was taken verbatim for CocoaPods-Core.

  #-------------------------------------------------------------------------#

  # Wraps an exception raised by a DSL file in order to show to the user the
  # contents of the line that raised the exception.
  #
  class DSLError < StandardError
    # @return [String] the description that should be presented to the user.
    #
    attr_reader :description

    # @return [String] the path of the dsl file that raised the exception.
    #
    attr_reader :dsl_path

    # @return [Exception] the backtrace of the exception raised by the
    #         evaluation of the dsl file.
    #
    attr_reader :backtrace

    # @param [Exception] backtrace @see backtrace
    # @param [String]    dsl_path  @see dsl_path
    #
    def initialize(description, dsl_path, backtrace, contents = nil)
      @description = description
      @dsl_path    = dsl_path
      @backtrace   = backtrace
      @contents    = contents
    end

    # @return [String] the contents of the DSL that cause the exception to
    #         be raised.
    #
    def contents
      @contents ||= begin
        dsl_path && File.exist?(dsl_path) && File.read(dsl_path)
      end
    end

    # The message of the exception reports the content of podspec for the
    # line that generated the original exception.
    #
    # @example Output
    #
    #   Invalid podspec at `RestKit.podspec` - undefined method
    #   `exclude_header_search_paths=' for #<Pod::Specification for
    #   `RestKit/Network (0.9.3)`>
    #
    #       from spec-repos/master/RestKit/0.9.3/RestKit.podspec:36
    #       -------------------------------------------
    #           # because it would break: #import <CoreData/CoreData.h>
    #    >      ns.exclude_header_search_paths = 'Code/RestKit.h'
    #         end
    #       -------------------------------------------
    #
    # @return [String] the message of the exception.
    #
    def message
      @message ||= begin
        description, stacktrace = parse.values_at(:description, :stacktrace)

        msg = description
        msg = msg.red if msg.respond_to?(:red)
        msg << stacktrace if stacktrace
        msg
      end
    end

    def to_markdown
      @markdown ||= begin
        description, stacktrace = parse.values_at(:description, :stacktrace)

        # Highlight failed method in markdown
        description = description.tr("'", "`")

        # Escape markdown brackets
        description = description.gsub(/<|>/) { |bracket| "\\#{bracket}" }

        md = "## Danger has errored"
        md << "#{description}\n"
        md << "```#{stacktrace}```" if stacktrace

        Markdown.new(md, nil, nil)
      end
    end

    private

    def parse
      result = {}

      trace_line, description = parse_line_number_from_description
      latest_version = Danger.danger_outdated?

      result[:description] = "\n[!] #{description}"
      result[:description] << upgrade_message(latest_version) if latest_version

      return result unless backtrace && dsl_path && contents

      trace_line = backtrace.find { |l| l.include?(dsl_path.to_s) } || trace_line
      return result unless trace_line
      line_numer = trace_line.split(":")[1].to_i - 1
      return result unless line_numer

      lines      = contents.lines
      indent     = " #  "
      indicator  = indent.tr("#", ">")
      first_line = line_numer.zero?
      last_line  = (line_numer == (lines.count - 1))

      result[:stacktrace] = "\n"
      result[:stacktrace] << "#{indent}from #{trace_line.gsub(/:in.*$/, '')}\n"
      result[:stacktrace] << "#{indent}-------------------------------------------\n"
      result[:stacktrace] << "#{indent}#{lines[line_numer - 1]}" unless first_line
      result[:stacktrace] << "#{indicator}#{lines[line_numer]}"
      result[:stacktrace] << "#{indent}#{lines[line_numer + 1]}" unless last_line
      result[:stacktrace] << "\n" unless result[:stacktrace].end_with?("\n")
      result[:stacktrace] << "#{indent}-------------------------------------------\n"

      result
    end

    def parse_line_number_from_description
      description = self.description
      if dsl_path && description =~ /((#{Regexp.quote File.expand_path(dsl_path)}|#{Regexp.quote dsl_path.to_s}):\d+)/
        trace_line = Regexp.last_match[1]
        description = description.sub(/#{Regexp.quote trace_line}:\s*/, "")
      end
      [trace_line, description]
    end

    def upgrade_message(latest_version)
      ". Updating the Danger gem might fix the issue. "\
      "Your Danger version: #{Danger::VERSION}, "\
      "latest Danger version: #{latest_version}\n"
    end
  end
end
