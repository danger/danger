module Danger
  class Dangerfile
    # Anything inside this module is considered public API, and in the future
    # documentation will be generated from it via rdoc.

    module DSL
      # @!group Danger Zone
      # Provides access to the raw Travis/Circle/Buildkite/GitHub objects, which
      # you can use to pull out extra bits of information. _Warning_
      # the interfaces of these objects is **not** considered a part of the Dangerfile public
      # API, and is viable to change occasionally on the whims of developers.
      # @return [EnvironmentManager]

      attr_reader :env

      private

      def initialize
        load_default_plugins
      end

      def load_default_plugins
        Dir["./danger_plugins/*.rb"].each do |file|
          require File.expand_path(file)
        end
      end
    end
  end
end
