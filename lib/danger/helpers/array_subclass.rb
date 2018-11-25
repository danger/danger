module Danger
  module Helpers
    module ArraySubclass
      include Comparable

      def initialize(array)
        @__array__ = array
      end

      def kind_of?(compare_class)
        return true if compare_class == self.class

        dummy.kind_of?(compare_class)
      end

      def method_missing(name, *args, &block)
        super unless __array__.respond_to?(name)

        respond_to_method(name, *args, &block)
      end

      def respond_to_missing?(name)
        __array__.respond_to?(name) || super
      end

      def to_a
        __array__
      end

      def to_ary
        __array__
      end

      def <=>(other)
        return unless other.kind_of?(self.class)

        __array__ <=> other.instance_variable_get(:@__array__)
      end

      private

      attr_accessor :__array__

      def dummy
        Class.new(Array).new
      end

      def respond_to_method(name, *args, &block)
        result = __array__.send(name, *args, &block)
        return result unless result.kind_of?(Array)

        if name =~ /!/
          __array__ = result
          self
        else
          self.class.new(result)
        end
      end
    end
  end
end
