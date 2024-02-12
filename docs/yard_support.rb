# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

# Custom markup provider class that always renders Kramdown using GFM (Github Flavored Markdown).
# @see https://stackoverflow.com/a/63683511/6918498
class KramdownGfmDocument < Kramdown::Document
  def initialize(source, options = {})
    options[:input] = "GFM" unless options.key?(:input)
    super(source, options)
  end
end

# Register the new provider as the highest priority option for Markdown.
YARD::Templates::Helpers::MarkupHelper::MARKUP_PROVIDERS[:markdown].insert(0, {const: KramdownGfmDocument.name})
