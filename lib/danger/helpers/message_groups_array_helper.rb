module Danger
  module Helpers
    module MessageGroupsArrayHelper
      FakeArray = Struct.new(:count) do
        def empty?
          count.zero?
        end
      end

      def fake_warnings_array
        FakeArray.new(counts[:warnings])
      end

      def fake_errors_array
        FakeArray.new(counts[:errors])
      end

      def counts
        return @counts if @counts

        @counts = { warnings: 0, errors: 0 }
        each do |message_group, counts|
          group_stats = message_group.stats
          @counts[:warnings] += group_stats[:warnings_count]
          @counts[:errors] += group_stats[:errors_count]
        end
        @counts
      end
    end
  end
end
