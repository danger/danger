require "danger/danger_core/message_group"
require "danger/helpers/message_groups_array_helper"

RSpec.describe Danger::Helpers::MessageGroupsArrayHelper do
  subject(:array) do
    class << message_groups
      include Danger::Helpers::MessageGroupsArrayHelper
    end
    message_groups
  end
  let(:message_groups) { [] }

  it { is_expected.to be_a Array }
  it { is_expected.to respond_to :fake_warnings_array }
  it { is_expected.to respond_to :fake_errors_array }

  shared_context "with two message groups" do
    let(:message_group_a) { double(Danger::MessageGroup.new) }
    let(:message_group_b) { double(Danger::MessageGroup.new) }
    let(:message_groups) { [message_group_a, message_group_b] }
  end

  describe "#fake_warnings_array" do
    subject { array.fake_warnings_array }

    context "with no message groups" do
      it "returns an fake array with a count method which returns 0" do
        expect(subject.count).to eq 0
      end
    end

    context "with two message groups" do
      include_context "with two message groups"

      before do
        allow(message_group_a).to receive(:stats).and_return(warnings_count: 10, errors_count: 35)
        allow(message_group_b).to receive(:stats).and_return(warnings_count: 6, errors_count: 9)
      end

      it "returns an fake array with a count method which returns 0" do
        expect(subject.count).to eq 16
      end
    end
  end

  describe "#fake_errors_array" do
    subject { array.fake_errors_array }

    context "with no message groups" do
      it "returns an fake array with a count method which returns 0" do
        expect(subject.count).to eq 0
      end
    end

    context "with two message groups" do
      include_context "with two message groups"

      before do
        allow(message_group_a).to receive(:stats).and_return(warnings_count: 10, errors_count: 35)
        allow(message_group_b).to receive(:stats).and_return(warnings_count: 6, errors_count: 9)
      end

      it "returns an fake array with a count method which returns 44" do
        expect(subject.count).to eq 44
      end
    end
  end
end
