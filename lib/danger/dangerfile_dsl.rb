module Danger
  class Dangerfile
    module DSL
      public

      # @!group Enviroment
      # @return [EnvironmentManager] Provides access to the raw Travis/Circle/GitHub
      # objects, which you can use to pull out extra bits of information. _Warning_
      # the api of these objects is **not** considered a part of the Dangerfile public
      # API, and is viable to change occasionally on the whims of developers.

      attr_reader :env

      # @!group Code
      # @return [Number] The total amount of lines of code in the diff
      #
      attr_reader :lines_of_code

      # @return [Array of Strings] The list of files modified
      #
      attr_reader :files_modified

      # @return [Array of Strings] The list of files removed
      #
      attr_reader :files_removed

      # @return [Array of Strings] The list of files added
      #
      attr_reader :files_added

      # @!group Pull Request Meta
      # @return [String] The title of the PR
      #
      attr_reader :pr_title

      # @return [String] The body of the PR
      #
      attr_reader :pr_body

      # Declares a CI blocking error
      #
      # @param    [String] message
      #           The message to present to the user
      def fail(message)
        self.failures << message
        puts "fail #{fail}"
      end

      # Specifies a problem, but not critical
      #
      # @param    [String] message
      #           The message to present to the user
      def warn(_message)
        self.warnings << "message"
        puts "warn #{fail}"
      end
    end
  end
end
