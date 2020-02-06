module Danger
  class EmojiMapper
    DATA = {
      "github" => {
        "no_entry_sign"    => "🚫",
        "warning"          => "⚠️",
        "book"             => "📖",
        "white_check_mark" => "✅"
      },
      "bitbucket_server" => {
        "no_entry_sign"    => ":no_entry_sign:",
        "warning"          => ":warning:",
        "book"             => ":book:",
        "white_check_mark" => ":white_check_mark:"
      }
    }.freeze

    def initialize(template)
      template.sub!('_inline', '')
      @template = DATA.has_key?(template) ? template : "github"
    end

    def map(emoji)
      emoji.delete! ":"
      DATA[template][emoji]
    end

    private

    attr_reader :template
  end
end
