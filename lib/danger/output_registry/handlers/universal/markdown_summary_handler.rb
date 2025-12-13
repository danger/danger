# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module Universal
        # Generates a markdown summary of violations.
        #
        # Creates a markdown formatted summary of violations, useful for
        # including in commit messages, pull request descriptions, or reports.
        #
        class MarkdownSummaryHandler < OutputHandler
          # Executes the handler to generate markdown summary.
          #
          # @return [void]
          #
          def execute
            return unless violations?

            output_path = ENV["DANGER_MARKDOWN_OUTPUT_PATH"]
            if output_path
              write_markdown_file(output_path)
            else
              puts generate_markdown
            end
          end

          protected

          # Generates markdown summary of violations.
          #
          # @return [String] Markdown formatted summary
          #
          def generate_markdown
            parts = []

            parts << "# Danger Review"
            parts << ""

            if violations?
              parts << "## Summary"
              parts << ""
              parts << "- **Errors:** #{errors.count}"
              parts << "- **Warnings:** #{warnings.count}"
              parts << "- **Messages:** #{messages.count}"
              parts << ""
            end

            unless errors.empty?
              parts << "## 🚫 Errors"
              parts << ""
              errors.each do |error|
                location = error.file && error.line ? " — `#{error.file}:#{error.line}`" : ""
                parts << "- #{error.message}#{location}"
              end
              parts << ""
            end

            unless warnings.empty?
              parts << "## ⚠️ Warnings"
              parts << ""
              warnings.each do |warning|
                location = warning.file && warning.line ? " — `#{warning.file}:#{warning.line}`" : ""
                parts << "- #{warning.message}#{location}"
              end
              parts << ""
            end

            unless messages.empty?
              parts << "## 💬 Messages"
              parts << ""
              messages.each do |message|
                location = message.file && message.line ? " — `#{message.file}:#{message.line}`" : ""
                parts << "- #{message.message}#{location}"
              end
              parts << ""
            end

            parts.join("\n")
          end

          # Writes markdown summary to a file.
          #
          # @param path [String] File path to write to
          # @return [void]
          #
          def write_markdown_file(path)
            File.write(path, generate_markdown)
            log_warning("Wrote markdown summary to #{path}")
          rescue StandardError => e
            log_warning("Failed to write markdown file: #{e.message}")
          end
        end
      end
    end
  end
end
