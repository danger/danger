module Danger
  module Helpers
    module CommentsParsingHelper
      # !@group Extension points
      # Produces a message-like from a row in a comment table
      #
      # @param [String] row
      #        The content of the row in the table
      #
      # @return [Violation or Markdown] the extracted message
      def parse_message_from_row(row)
        Violation.new(row, true)
      end

      def parse_tables_from_comment(comment)
        comment.split("</table>")
      end

      def violations_from_table(table)
        row_regex = %r{<td data-sticky="true">(?:<del>)?(.*?)(?:</del>)?\s*</td>}im
        table.scan(row_regex).flatten.map do |row|
          parse_message_from_row(row.strip)
        end
      end

      def parse_comment(comment)
        tables = parse_tables_from_comment(comment)
        violations = {}
        tables.each do |table|
          match = danger_table?(table)
          next unless match
          title = match[1]
          kind = table_kind_from_title(title)
          next unless kind

          violations[kind] = violations_from_table(table)
        end

        violations.reject { |_, v| v.empty? }
      end

      def table_kind_from_title(title)
        if title =~ /error/i
          :error
        elsif title =~ /warning/i
          :warning
        elsif title =~ /message/i
          :message
        end
      end

      private

      GITHUB_OLD_REGEX = %r{<th width="100%"(.*?)</th>}im
      NEW_REGEX = %r{<th.*data-danger-table="true"(.*?)</th>}im

      def danger_table?(table)
        # The old GitHub specific method relied on
        # the width of a `th` element to find the table
        # title and determine if it was a danger table.
        # The new method uses a more robust data-danger-table
        # tag instead.
        match = GITHUB_OLD_REGEX.match(table)
        return match if match

        return NEW_REGEX.match(table)
      end
    end
  end
end
