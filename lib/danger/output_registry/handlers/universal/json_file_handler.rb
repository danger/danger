# frozen_string_literal: true

require "json"

module Danger
  module OutputRegistry
    module Handlers
      module Universal
        # Writes violations to a JSON file.
        #
        # Exports violations in JSON format for consumption by other tools and CI systems.
        # File location controlled via DANGER_JSON_OUTPUT_PATH environment variable.
        #
        class JSONFileHandler < OutputHandler
          # Executes the handler to write JSON output file.
          #
          # Defaults to "danger_output.json" if DANGER_JSON_OUTPUT_PATH is not set.
          #
          # @return [void]
          #
          def execute
            output_path = ENV["DANGER_JSON_OUTPUT_PATH"] || "danger_output.json"
            write_json_file(output_path)
          end

          protected

          # Writes violations to a JSON file.
          #
          # @param path [String] File path to write to
          # @return [void]
          #
          def write_json_file(path)
            validate_output_path(path)

            output = {
              errors: violations_to_json(errors),
              warnings: violations_to_json(warnings),
              messages: violations_to_json(messages),
              summary: {
                total: errors.count + warnings.count + messages.count,
                errors: errors.count,
                warnings: warnings.count,
                messages: messages.count
              }
            }

            File.write(path, JSON.pretty_generate(output))
            log_warning("Wrote JSON output to #{path}")
          rescue StandardError => e
            log_warning("Failed to write JSON file: #{e.message}")
          end

          # Validates that the output path is writable.
          #
          # @param path [String] File path to validate
          # @return [void]
          # @raise [StandardError] if path is not writable
          #
          def validate_output_path(path)
            dir = File.dirname(path)
            return if File.writable?(dir) || dir == "."

            raise "Output directory '#{dir}' is not writable"
          end

          # Converts violations to JSON-serializable format.
          #
          # @param violations [Array] Violations to convert
          # @return [Array<Hash>] JSON-serializable violations
          #
          def violations_to_json(violations)
            violations.map do |v|
              {
                message: v.message,
                file: v.file,
                line: v.line
              }.compact
            end
          end
        end
      end
    end
  end
end
