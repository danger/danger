require "kramdown"
require "danger/helpers/comments_parsing_helper"
require "danger/helpers/emoji_mapper"
require "danger/helpers/find_max_num_violations"

module Danger
  module Helpers
    module CommentsHelper
      # This might be a bit weird, but table_kind_from_title is a shared dependency for
      # parsing and generating. And rubocop was adamant about file size so...
      include Danger::Helpers::CommentsParsingHelper

      def markdown_parser(text)
        Kramdown::Document.new(text, input: "GFM", smart_quotes: %w[apos apos quot quot])
      end

      # !@group Extension points
      # Produces a markdown link to the file the message points to
      #
      # request_source implementations are invited to override this method with their
      # vendor specific link.
      #
      # @param [Violation or Markdown] message
      # @param [Bool] Should hide any generated link created
      #
      # @return [String] The Markdown compatible link
      def markdown_link_to_message(message, _)
        "#{message.file}#L#{message.line}"
      end

      # !@group Extension points
      # Determine whether two messages are equivalent
      #
      # request_source implementations are invited to override this method.
      # This is mostly here to enable sources to detect when inlines change only in their
      # commit hash and not in content per-se. since the link is implementation dependant
      # so should be the comparison.
      #
      # @param [Violation or Markdown] m1
      # @param [Violation or Markdown] m2
      #
      # @return [Boolean] whether they represent the same message
      def messages_are_equivalent(m1, m2)
        m1 == m2
      end

      def process_markdown(violation, hide_link = false)
        message = violation.message
        message = "#{markdown_link_to_message(violation, hide_link)}#{message}" if violation.file && violation.line

        html = markdown_parser(message).to_html
        # Remove the outer `<p>` and `</p>`.
        html = html.strip.sub(%r{\A<p>(.*)</p>\z}m, '\1')
        Violation.new(html, violation.sticky, violation.file, violation.line)
      end

      def table(name, emoji, violations, all_previous_violations, template: "github")
        content = violations
        content = content.map { |v| process_markdown(v) } unless ["bitbucket_server", "vsts"].include?(template)

        kind = table_kind_from_title(name)
        previous_violations = all_previous_violations[kind] || []
        resolved_violations = previous_violations.reject do |pv|
          content.count { |v| messages_are_equivalent(v, pv) } > 0
        end

        resolved_messages = resolved_violations.map(&:message).uniq
        count = content.count

        {
          name: name,
          emoji: emoji,
          content: content,
          resolved: resolved_messages,
          count: count
        }
      end

      def apply_template(tables: [], markdowns: [], danger_id: "danger", template: "github", request_source: template)
        require "erb"

        md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/#{template}.md.erb")

        # erb: http://www.rrn.dk/rubys-erb-templating-system
        # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
        @tables = tables
        @markdowns = markdowns.map(&:message)
        @danger_id = danger_id
        @emoji_mapper = EmojiMapper.new(request_source.sub("_inline",""))

        return ERB.new(File.read(md_template), 0, "-").result(binding)
      end

      def generate_comment(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: {}, danger_id: "danger", template: "github")
        apply_template(
          tables: [
            table("Error", "no_entry_sign", errors, previous_violations, template: template),
            table("Warning", "warning", warnings, previous_violations, template: template),
            table("Message", "book", messages, previous_violations, template: template)
          ],
          markdowns: markdowns,
          danger_id: danger_id,
          template: template
        )
      end

      # resolved is essentially reserved for future use - eventually we might
      # have some nice generic resolved-thing going :)
      def generate_message_group_comment(message_group:,
                                         danger_id: "danger",
                                         resolved: [],
                                         template: "github")
        # cheating a bit - I don't want to alter the apply_template API
        # so just sneak around behind its back setting some instance variables
        # to get them to show up in the template
        @message_group = message_group
        @resolved = resolved
        request_source_name = template.sub("_message_group", "")


        apply_template(danger_id: danger_id,
                       markdowns: message_group.markdowns,
                       template: template,
                       request_source: request_source_name)
          .sub(/\A\n*/, "")
      end

      def generate_inline_comment_body(emoji,
                                       message,
                                       danger_id: "danger",
                                       resolved: false,
                                       template: "github")
        apply_template(
          tables: [{ content: [message], resolved: resolved, emoji: emoji }],
          danger_id: danger_id,
          template: "#{template}_inline"
        )
      end

      def generate_inline_markdown_body(markdown, danger_id: "danger", template: "github")
        apply_template(
          markdowns: [markdown],
          danger_id: danger_id,
          template: "#{template}_inline"
        )
      end

      def generate_description(warnings: nil, errors: nil, template: "github")
        emoji_mapper = EmojiMapper.new(template)
        if errors.empty? && warnings.empty?
          return "All green. #{random_compliment}"
        else
          message = "#{emoji_mapper.map('warning')} "
          message += "#{'Error'.danger_pluralize(errors.count)}. " unless errors.empty?
          message += "#{'Warning'.danger_pluralize(warnings.count)}. " unless warnings.empty?
          message += "Don't worry, everything is fixable."
          return message
        end
      end

      def random_compliment
        ["Well done.", "Congrats.", "Woo!",
         "Yay.", "Jolly good show.", "Good on 'ya.", "Nice work."].sample
      end

      private

      def pluralize(string, count)
        string.danger_pluralize(count)
      end

      def truncate(string)
        max_message_length = 30
        string.danger_truncate(max_message_length)
      end
    end
  end
end
