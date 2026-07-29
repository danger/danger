# frozen_string_literal: true

module Danger
  module OutputRegistry
    module Handlers
      module Universal
        # Writes violations to a JUnit XML file.
        #
        # Exports violations in JUnit XML format for CI integration.
        # File location controlled via DANGER_JUNIT_OUTPUT_PATH environment variable.
        #
        class JUnitXMLHandler < OutputHandler
          # Executes the handler to write JUnit XML output file.
          #
          # @return [void]
          #
          def execute
            output_path = ENV["DANGER_JUNIT_OUTPUT_PATH"]
            return unless output_path

            write_junit_file(output_path)
          end

          protected

          # Writes violations to a JUnit XML file.
          #
          # @param path [String] File path to write to
          # @return [void]
          #
          def write_junit_file(path)
            validate_output_path(path)

            total_tests = errors.count + warnings.count + messages.count
            total_failures = errors.count
            total_skipped = warnings.count

            xml = build_junit_xml(total_tests, total_failures, total_skipped)

            File.write(path, xml)
            log_warning("Wrote JUnit XML output to #{path}")
          rescue StandardError => e
            log_warning("Failed to write JUnit XML file: #{e.message}")
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

          # Builds JUnit XML document.
          #
          # @param total [Integer] Total test count
          # @param failures [Integer] Failure count
          # @param skipped [Integer] Skipped count
          # @return [String] XML document
          #
          def build_junit_xml(total, failures, skipped)
            parts = [
              '<?xml version="1.0" encoding="UTF-8"?>',
              "<testsuites>",
              %(<testsuite name="Danger" tests="#{total}" failures="#{failures}" skipped="#{skipped}">)
            ]

            errors.each do |violation|
              parts << build_failure_case(violation)
            end

            warnings.each do |violation|
              parts << build_skipped_case(violation)
            end

            messages.each do |violation|
              parts << build_passed_case(violation)
            end

            parts << "</testsuite>"
            parts << "</testsuites>"

            parts.join("\n")
          end

          # Extracts location string from a violation.
          #
          # @param violation [Object] Violation to extract location from
          # @return [String] Location string " (file:line)" or empty string
          #
          def violation_location(violation)
            violation.file && violation.line ? " (#{violation.file}:#{violation.line})" : ""
          end

          # Builds a failed test case.
          #
          # @param violation [Object] Violation to build case for
          # @return [String] XML test case
          #
          def build_failure_case(violation)
            location = violation_location(violation)
            %(<testcase name="error: #{escape_xml(violation.message)}"><failure>#{escape_xml(violation.message)}#{escape_xml(location)}</failure></testcase>)
          end

          # Builds a skipped test case.
          #
          # @param violation [Object] Violation to build case for
          # @return [String] XML test case
          #
          def build_skipped_case(violation)
            location = violation_location(violation)
            %(<testcase name="warning: #{escape_xml(violation.message)}"><skipped>#{escape_xml(violation.message)}#{escape_xml(location)}</skipped></testcase>)
          end

          # Builds a passed test case.
          #
          # @param violation [Object] Violation to build case for
          # @return [String] XML test case
          #
          def build_passed_case(violation)
            location = violation_location(violation)
            %(<testcase name="message: #{escape_xml(violation.message)}">#{escape_xml(location)}</testcase>)
          end

          # Escapes XML special characters.
          #
          # @param text [String] Text to escape
          # @return [String] Escaped text
          #
          def escape_xml(text)
            text.to_s
              .gsub("&", "&amp;")
              .gsub("<", "&lt;")
              .gsub(">", "&gt;")
              .gsub('"', "&quot;")
              .gsub("'", "&apos;")
          end
        end
      end
    end
  end
end
