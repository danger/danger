module Fastlane
  module Actions
    class RubocopAction < Action
      def self.run(_params)
        sh "rubocop -D"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs the code style checks"
      end

      def self.available_options
        []
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.is_supported?(_platform)
        true
      end
    end
  end
end
