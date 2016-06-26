require 'danger/commands/plugin_abstract'
require 'danger/plugin_support/plugin_parser'

module Danger
  class PluginLint < PluginAbstract
    self.summary = 'Lints a plugin'
    self.command = 'lint'

    def initialize(argv)
      @plugin_ref = argv.shift_argument
      super
    end

    def self.options
      [
        ['[path]', 'The path of the ruby file you want to lint'],
      ].concat(super)
    end

    def run
      require 'yard'

      # Sometimes there's caching issues, they look like this:
      #  TypeError:
      #   incompatible marshal file format (can't be read)
      #     format version 4.8 required; 109.111 given

      # `rm -rf '~/.yard/'`

      if File.exist? @plugin_ref
        path = @plugin_ref
      else
        raise "Could not find a file at path"
      end

      parser = PluginParser.new(path)
      parser.parse
      json = parser.to_json

      cork.message json
    end
  end
end
