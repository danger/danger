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

    TYPE_TO_EMOJI = {
      error: "no_entry_sign",
      warning: "warning",
      message: "book",
    }.freeze

    def initialize(template)
      @template = DATA.has_key?(template) ? template : "github"
    end

    def map(emoji)
      emoji&.delete! ":"
      DATA[template][emoji]
    end

    def from_type(type)
      map(TYPE_TO_EMOJI[type])
    end

    private

    attr_reader :template
  end
end
