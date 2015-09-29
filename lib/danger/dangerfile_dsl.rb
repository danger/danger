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

    end
  end
end
