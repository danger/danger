module Danger
  class ExampleManyMethodsPlugin < Plugin
    def one
    end

    # Thing two
    #
    def two(param1)
    end

    def two_point_five(param1 = nil)
    end

    # Thing three
    #
    # @param   [String] param1
    #          A thing thing, defaults to nil.
    # @return  [void]
    #
    def three(param1 = nil)
    end

    # Thing four
    #
    # @param   [Number] param1
    #          A thing thing, defaults to nil.
    # @param   [String] param2
    #          Another param
    # @return  [String]
    #
    def four(param1 = nil, param2)
    end

    # Thing five
    #
    # @param   [Array<String>] param1
    #          A thing thing.
    # @param   [Filepath] param2
    #          Another param
    # @return  [String]
    #
    def five(param1 = [], param2, param3)
    end

    # Does six
    # @return  [Bool]
    #
    def six?
    end

    # Attribute docs
    #
    # @return   [Array<String>]
    attr_accessor :seven

    attr_accessor :eight
  end
end
