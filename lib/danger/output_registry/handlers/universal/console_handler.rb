# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module Universal
        # Outputs violations to console/stdout.
        #
        # This handler prints violations in a human-readable format to the console,
        # useful for local development and debugging.
        #
        class ConsoleHandler < OutputHandler
          # Executes the handler to output violations to console.
          #
          # Always outputs something, even when there are no violations, so users
          # know that Danger ran successfully.
          #
          # @return [void]
          #
          def execute
            print_violations
          end

          protected

          # Prints violations to stdout.
          #
          # @return [void]
          #
          def print_violations
            puts "\n#{'=' * 60}"
            puts "Danger Review Results"
            puts "=" * 60

            if violations?
              print_section("Errors", errors, "🚫")
              print_section("Warnings", warnings, "⚠️")
              print_section("Messages", messages, "💬")
            else
              puts "\n✅ No violations found!"
            end

            puts "#{'=' * 60}\n"
          end

          # Prints a section of violations.
          #
          # @param title [String] Section title
          # @param violations [Array] Violations to print
          # @param emoji [String] Emoji prefix
          # @return [void]
          #
          def print_section(title, violations, emoji)
            return if violations.empty?

            puts "\n#{emoji} #{title}:"
            violations.each do |violation|
              location = violation.file && violation.line ? " (#{violation.file}:#{violation.line})" : ""
              puts "  - #{violation.message}#{location}"
            end
          end
        end
      end
    end
  end
end
