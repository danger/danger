require "danger/danger_core/messages/violation"
require "danger/danger_core/message_group"

RSpec.describe Danger::MessageGroup do
  subject(:message_group) { described_class.new(file: file, line: line) }

  shared_examples_for "with varying line and file" do |behaves_like:|
    context "with nil file and line" do
      let(:file) { nil }
      let(:line) { nil }
      it_behaves_like behaves_like
    end

    context "with a filename and nil line" do
      let(:file) { "test.txt" }
      let(:line) { nil }
      it_behaves_like behaves_like
    end

    context "with a line and nil filename" do
      let(:file) { nil }
      let(:line) { 180 }
      it_behaves_like behaves_like
    end
    context "with a file and line" do
      let(:file) { "test.txt" }
      let(:line) { 190 }
      it_behaves_like behaves_like
    end
  end

  describe "#same_line?" do
    subject { message_group.same_line? other }

    shared_examples_for "true when same line" do
      context "on the same line" do
        let(:other_file) { file }
        let(:other_line) { line }

        it { is_expected.to be true }
      end

      context "on a different line" do
        let(:other_file) { file }
        let(:other_line) { 200 }

        it { is_expected.to be false }
      end

      context "in a different file" do
        let(:other_file) { "jeff.txt" }
        let(:other_line) { line }

        it { is_expected.to be false }
      end

      context "in a different on a different line" do
        let(:other_file) { "jeff.txt" }
        let(:other_line) { 200 }

        it { is_expected.to be false }
      end
    end

    context "when other is a Violation" do
      let(:other) { Danger::Violation.new("test message",
                                          false,
                                          other_file,
                                          other_line) }
      include_examples "with varying line and file", behaves_like: "true when same line"
    end

    context "when other is a Markdown" do
      let(:other) { Danger::Markdown.new("test message",
                                         other_file,
                                         other_line) }

      include_examples "with varying line and file", behaves_like: "true when same line"
    end

    context "when other is a MessageGroup" do
      let(:other) { described_class.new(file: other_file,
                                        line: other_line) }

      include_examples "with varying line and file", behaves_like: "true when same line"
    end
  end

  describe "<<" do
    subject { message_group << message }

    shared_examples_for "adds when same line" do
      context "on the same line" do
        let(:other_file) { file }
        let(:other_line) { line }

        it { expect { subject }.to change { message_group.messages.count }.by 1 }
      end

      context "on a different line" do
        let(:other_file) { file }
        let(:other_line) { 200 }

        it { expect { subject }.not_to change { message_group.messages.count } }
      end

      context "in a different file" do
        let(:other_file) { "jeff.txt" }
        let(:other_line) { line }

        it { expect { subject }.not_to change { message_group.messages.count } }
      end

      context "in a different file on a different line" do
        let(:other_file) { "jeff.txt" }
        let(:other_line) { 200 }

        it { expect { subject }.not_to change { message_group.messages.count } }
      end
    end

    context "when message is a Violation" do
      let(:message) { Danger::Violation.new("test message",
                                            false,
                                            other_file,
                                            other_line) }
      include_examples "with varying line and file", behaves_like: "adds when same line"
    end

    context "when message is a Markdown" do
      let(:message) { Danger::Markdown.new("test message",
                                           other_file,
                                           other_line) }

      include_examples "with varying line and file", behaves_like: "adds when same line"
    end
  end

  describe "#stats" do
    subject { message_group.stats }
    let(:file) { nil }
    let(:line) { nil }

    before do
      warnings.each { |w| message_group << w }
      errors.each { |e| message_group << e }
    end

    let(:warnings) { [] }
    let(:errors) { [] }

    context "when group has no warnings" do
      context "when group has no errors" do
        it { is_expected.to eq(warnings_count: 0, errors_count: 0) }
      end

      context "when group has one error" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] }

        it { is_expected.to eq(warnings_count: 0, errors_count: 1) }
      end

      context "when group has 10 errors" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] * 10 }

        it { is_expected.to eq(warnings_count: 0, errors_count: 10) }
      end
    end

    context "when group has one warning" do
      let(:warnings) { [Danger::Violation.new("test", false, file, line, type: :warning)] }

      context "when group has no errors" do
        it { is_expected.to eq(warnings_count: 1, errors_count: 0) }
      end

      context "when group has one error" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] }

        it { is_expected.to eq(warnings_count: 1, errors_count: 1) }
      end

      context "when group has 10 errors" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] * 10 }

        it { is_expected.to eq(warnings_count: 1, errors_count: 10) }
      end
    end

    context "when group has 10 warnings" do
      let(:warnings) { [Danger::Violation.new("test", false, file, line, type: :warning)] * 10 }

      context "when group has no errors" do
        it { is_expected.to eq(warnings_count: 10, errors_count: 0) }
      end

      context "when group has one error" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] }

        it { is_expected.to eq(warnings_count: 10, errors_count: 1) }
      end

      context "when group has 10 errors" do
        let(:errors) { [Danger::Violation.new("test", false, file, line, type: :error)] * 10 }

        it { is_expected.to eq(warnings_count: 10, errors_count: 10) }
      end
    end
  end

  describe "#markdowns" do
    subject { message_group.markdowns }
    let(:file) { nil }
    let(:line) { nil }

    before do
      messages.each { |m| message_group << m }
      markdowns.each { |m| message_group << m }
    end

    let(:markdowns) { [] }
    let(:messages) { [] }

    context "with no markdowns" do
      it { is_expected.to eq [] }
    end

    context "with 2 markdowns" do
      let(:markdowns) { [Danger::Markdown.new("hello"), Danger::Markdown.new("hi")] }

      context "with no other messages" do

        it "has both markdowns" do
          expect(Set.new(subject)).to eq Set.new(markdowns)
        end
      end
      context "with other messages" do
        let(:messages) { [Danger::Violation.new("warning!",type: :warning), Danger::Violation.new("error!", type: :error)] }

        it "still only has both markdowns" do
          expect(Set.new(subject)).to eq Set.new(markdowns)
        end
      end
    end
  end
end
