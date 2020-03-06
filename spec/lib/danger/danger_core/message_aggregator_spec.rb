require "danger/danger_core/message_aggregator"
require "danger/danger_core/messages/violation"

module MessageFactories
  def violation(type, file, line)
    Danger::Violation.new("test violation", false, file, line, type: type)
  end

  %I[error warning message].each do |type|
    define_method(type) do |file, line|
      violation(type, file, line)
    end
  end

  def markdown(file, line)
    Danger::Markdown.new("test markdown", file, line)
  end
end

RSpec.describe Danger::MessageAggregator do
  include MessageFactories

  describe "#aggregate" do
    subject { described_class.new(**args).aggregate }

    let(:args) do
      {
        warnings: warnings.shuffle,
        errors: errors.shuffle,
        messages: messages.shuffle,
        markdowns: markdowns.shuffle
      }
    end
    let(:warnings) { [] }
    let(:errors) { [] }
    let(:messages) { [] }
    let(:markdowns) { [] }

    context "with no messages" do
      it "returns an array with #fake_warnings_array and #fake_errors_array" do
        expect(subject).to be_a Array
        expect(subject).to respond_to :fake_warnings_array
        expect(subject).to respond_to :fake_errors_array
      end

      it "returns an array containing one group" do
        expect(subject.count).to eq 1
        group = subject.first
        expect(group.messages.count).to eq 0
        expect(group.file).to be nil
        expect(group.line).to be nil
      end
    end

    context "with one message of each type" do
      let(:errors) { [error(nil, nil)] }
      let(:warnings) { [warning(nil, nil)] }
      let(:messages) { [message(nil, nil)] }
      let(:markdowns) { [markdown(nil, nil)] }

      it "returns an array containing one group - with all the messages in it" do
        expect(subject.count).to eq 1
        group = subject.first
        expect(group.messages.count).to eq 4
        expect(group.file).to be nil
        expect(group.line).to be nil
      end

      it "sorts the messages by type" do
        group = subject.first
        expect(group.messages[0].type).to eq :error
        expect(group.messages[1].type).to eq :warning
        expect(group.messages[2].type).to eq :message
        expect(group.messages[3].type).to eq :markdown
      end
    end

    context "with a few messages in different files message of each type" do
      let(:file_a) { "README.md" }
      let(:file_b) { "buggy_app.rb" }

      # groups expected:
      # nil:
      #  nil: []
      #
      # file_a:
      #  1: [markdown]
      #  2: [message]
      #  3: [error, error, warning, message, markdown]
      #
      # file_b:
      #  1: [error, warning]
      #  2: [message]
      #  3: [error]

      let(:errors) do
        [
          [file_a, 3],
          [file_a, 3],
          [file_b, 1],
          [file_b, 3]
        ].map { |a| error(*a) }
      end

      let(:warnings) do
        [
          [file_a, 3],
          [file_b, 1]
        ].map { |a| warning(*a) }
      end

      let(:messages) do
        [
          [file_a, 2],
          [file_a, 3],
          [file_b, 2]
        ].map { |a| message(*a) }
      end

      let(:markdowns) do
        [
          [file_a, 1],
          [file_a, 3]
        ].map { |a| markdown(*a) }
      end

      it "returns an array containing one group - with all the messages in it" do
        expect(subject.count).to eq 7
        expect(subject.fake_warnings_array.count).to eq warnings.count
        expect(subject.fake_errors_array.count).to eq errors.count

        (nil_group, a1, a2, a3, b1, b2, b3) = subject
        expect(nil_group.messages).to eq []

        expect(a1.messages.map(&:type)).to eq [:markdown]
        expect([a1.file, a1.line]).to eq([file_a, 1])

        expect([a2.file, a2.line]).to eq([file_a, 2])
        expect(a2.messages.map(&:type)).to eq [:message]

        expect([a3.file, a3.line]).to eq([file_a, 3])
        expect(a3.messages.map(&:type)).to eq %i(error error warning message markdown)

        expect(b1.messages.map(&:type)).to eq %i(error warning)
        expect([b1.file, b1.line]).to eq([file_b, 1])

        expect([b2.file, b2.line]).to eq([file_b, 2])
        expect(b2.messages.map(&:type)).to eq [:message]

        expect([b3.file, b3.line]).to eq([file_b, 3])
        expect(b3.messages.map(&:type)).to eq [:error]
      end

      #it "sorts the messages by type" do
      #  group = subject.first
      #  expect(group.messages[0].type).to eq :error
      #  expect(group.messages[1].type).to eq :warning
      #  expect(group.messages[2].type).to eq :message
      #  expect(group.messages[3].type).to eq :markdown
      #end
    end
  end
end
