require "danger/danger_core/message_aggregator"
require "danger/danger_core/messages/violation"

RSpec.describe Danger::MessageAggregator do
  describe "#aggregate" do
    subject { described_class.new(**args).aggregate }
    let(:args) { { warnings: warnings, errors: errors, messages: messages, markdowns: markdowns } }
  end
end
