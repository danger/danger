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
        # Pretty-printing can be controlled via DANGER_JSON_PRETTY environment variable:
        # - "1", "true", "yes": Always pretty-print
        # - "0", "false", "no": Always compact
        # - not set: Auto-detect based on output size (pretty if > 1KB)
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
          # Uses smart formatting: compact by default, pretty-printed if output > 1KB
          # or if DANGER_JSON_PRETTY environment variable is set.
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

            json_content = format_json(output)
            File.write(path, json_content)
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

          # Formats hash as JSON with smart pretty-printing.
          #
          # Uses compact JSON for small outputs (< 1KB), pretty-printed for larger.
          # Can be controlled via DANGER_JSON_PRETTY environment variable:
          # - "1"/"true"/"yes": Always pretty-print
          # - "0"/"false"/"no": Always compact
          # - unset: Auto-detect based on size
          #
          # @param hash [Hash] Data to format as JSON
          # @return [String] JSON string
          #
          def format_json(hash)
            compact_json = JSON.generate(hash)

            # Check if pretty-printing is explicitly requested
            pretty_env = ENV["DANGER_JSON_PRETTY"]&.downcase
            case pretty_env
            when "1", "true", "yes"
              return JSON.pretty_generate(hash)
            when "0", "false", "no"
              return compact_json
            end

            # Auto-detect: pretty-print if compact is large (> 1KB)
            compact_json.size > 1024 ? JSON.pretty_generate(hash) : compact_json
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
