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
        "no_entry_sign"    => "\u274C",
        "warning"          => "⚠️",
        "book"             => "\u2728",
        "white_check_mark" => "\u2705"
      }
    }.freeze

    def initialize(template)
      @template = DATA.include?(template) ? template : "github"
    end

    def map(emoji)
      emoji.delete! ":"
      DATA[template][emoji]
    end

    private

    attr_reader :template
  end
end
