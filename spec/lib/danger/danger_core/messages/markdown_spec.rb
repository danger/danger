require_relative "./shared_examples"
require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"

RSpec.describe Danger::Markdown do
  subject(:markdown) { described_class.new(message, file, line) }
  let(:message) { "hello world" }
  let(:file) { nil }
  let(:line) { nil }

  describe "#initialize" do
    subject { described_class.new("hello world") }

    it "defaults file to nil" do
      expect(subject.file).to be nil
    end

    it "defaults line to nil" do
      expect(subject.line).to be nil
    end
  end

  describe "#<=>" do
    subject { markdown <=> other }
    context "when other is a Violation" do
      let(:other) { Danger::Violation.new("hello world", false, other_file, other_line) }
      let(:other_file) { "test" }
      let(:other_line) { rand(4000) }
      it { is_expected.to eq(1) }
    end

    context "when other is a Markdown" do
      let(:other) { Danger::Markdown.new("example message", other_file, other_line) }

      it_behaves_like "compares by file and line"
    end
  end
end
