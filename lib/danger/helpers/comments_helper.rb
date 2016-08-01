require "kramdown"

module Danger
  module Helpers
    module CommentsHelper
      def markdown_parser(text)
        Kramdown::Document.new(text, input: "GFM")
      end

      def parse_tables_from_comment(comment)
        comment.split("</table>")
      end

      # Produces a message-like from a row in a comment table
      #
      # @param [String] row
      #        The content of the row in the table
      #
      # @return [Violation or Markdown] the extracted message
      def parse_message_from_row(row)
        Violation.new(row, true, nil, nil)
      end

      def violations_from_table(table)
        row_regex = %r{<td data-sticky="true">(?:<del>)?(.*?)(?:</del>)?\s*</td>}im
        table.scan(row_regex).flatten.map do |row|
          parse_message_from_row(row.strip)
        end
      end

      # Produces a markdown link to the file the message points to
      #
      # request_source implementations are invited to override this method with their
      # vendor specific link.
      #
      # @param [Violation or Markdown] message
      #
      # @return [String] The Markdown compatible link
      def markdown_link_to_message(message)
        "#{messages.file}#L#{message.line}"
      end

      def process_markdown(violation)
        message = violation.message
        message = "#{markdown_link_to_message violation} - #{message}" if violation.file && violation.line

        html = markdown_parser(message).to_html
        # Remove the outer `<p>`, the -5 represents a newline + `</p>`
        html = html[3...-5] if html.start_with? "<p>"
        Violation.new(html, violation.sticky, violation.file, violation.line)
      end

      def parse_comment(comment)
        tables = parse_tables_from_comment(comment)
        violations = {}
        tables.each do |table|
          next unless table =~ %r{<th width="100%"(.*?)</th>}im
          title = Regexp.last_match(1)
          kind = table_kind_from_title(title)
          next unless kind

          violations[kind] = violations_from_table(table)
        end

        violations.reject { |_, v| v.empty? }
      end

      def table(name, emoji, violations, all_previous_violations)
        content = violations.map { |v| process_markdown(v) }
        messages = content.map(&:message).uniq
        kind = table_kind_from_title(name)
        previous_violations = all_previous_violations[kind] || []
        resolved_violations = previous_violations.map(&:message).uniq - messages
        count = content.count

        {
          name: name,
          emoji: emoji,
          content: content,
          resolved: resolved_violations,
          count: count
        }
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

      def generate_comment(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: {}, danger_id: "danger", template: "github")
        require "erb"

        md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/#{template}.md.erb")

        # erb: http://www.rrn.dk/rubys-erb-templating-system
        # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
        @tables = [
          table("Error", "no_entry_sign", errors, previous_violations),
          table("Warning", "warning", warnings, previous_violations),
          table("Message", "book", messages, previous_violations)
        ]
        @markdowns = markdowns.map(&:message)
        @danger_id = danger_id

        return ERB.new(File.read(md_template), 0, "-").result(binding)
      end

      def generate_description(warnings: nil, errors: nil)
        if errors.empty? && warnings.empty?
          return "All green. #{random_compliment}"
        else
          message = "⚠ "
          message += "#{'Error'.danger_pluralize(errors.count)}. " unless errors.empty?
          message += "#{'Warning'.danger_pluralize(warnings.count)}. " unless warnings.empty?
          message += "Don't worry, everything is fixable."
          return message
        end
      end

      def random_compliment
        compliment = ["Well done.", "Congrats.", "Woo!",
                      "Yay.", "Jolly good show.", "Good on 'ya.", "Nice work."]
        compliment.sample
      end
    end
  end
end
