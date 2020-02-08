require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"

def random_alphas(n)
  (0...n).map { ("a".."z").to_a[rand(26)] }
end

RSpec.describe Danger::Violation do
  subject(:violation) { described_class.new(message, sticky, file, line, type: type) }
  let(:message) { "hello world" }
  let(:sticky) { false }
  let(:file) { nil }
  let(:line) { nil }
  let(:type) { :warning }

  describe "#initialize" do
    subject { described_class.new("hello world", true) }

    it "defaults file to nil" do
      expect(subject.file).to be nil
    end

    it "defaults line to nil" do
      expect(subject.line).to be nil
    end

    it "defaults type to :warning" do
      expect(subject.type).to be :warning
    end

    context "when type is an invalid value" do
      let(:type) { :i_am_an_invalid_type! }

      it "raises ArgumentError" do
        expect { violation }.to raise_error(ArgumentError)
      end
    end

    context "when sticky is unset" do
      it "raises" do
        expect { described_class.new("hello world") }.to raise_error(ArgumentError)
      end
    end

    context "when message is unset" do
      it "raises" do
        expect { described_class.new }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#<=>" do
    subject { violation <=> other }
    let(:file) { "hello.txt" }
    let(:line) { 50 }

    shared_examples_for "compares by line" do
      context "when line is nil" do
        let(:line) { nil }

        context "when other_line is nil" do
          let(:other_line) { nil }
          it { is_expected.to eq(0) }
        end

        context "when other_line is not nil" do
          let(:other_line) { 1 }
          it { is_expected.to eq(-1) }
        end
      end

      context "when line is not nil" do
        context "when other_line is nil" do
          let(:other_line) { nil }
          it { is_expected.to eq(1) }
        end
        context "when lines are the same" do
          let(:other_line) { line }
          it { is_expected.to eq 0 }
        end

        context "when line < other_line" do
          let(:other_line) { line + 10 }
          it { is_expected.to eq(-1) }
        end

        context "when line < other_line" do
          let(:other_line) { line - 10 }
          it { is_expected.to eq(1) }
        end
      end
    end

    shared_examples_for "compares by file and line" do |_other_type|
      context "when other_type is :#{_other_type}" do
        let(:other_type) { _other_type }

        context "when file is nil" do
          let(:file) { nil }

          context "when other_file is nil" do
            let(:other_file) { nil }
            it { is_expected.to eq(0) }
          end

          context "when other_file is not nil" do
            let(:other_file) { 1 }
            it { is_expected.to eq(-1) }
          end
        end

        context "when file is not nil" do
          context "when other_file is nil" do
            let(:other_file) { nil }
            it { is_expected.to eq(1) }
          end
          context "when files are the same" do
            let(:other_file) { file }

            include_examples "compares by line"
          end

          context "when file < other_file" do
            let(:other_file) { "world.txt" }
            it { is_expected.to eq(-1) }
          end

          context "when file > other_file" do
            let(:other_file) { "aardvark.txt" }
            it { is_expected.to eq 1 }
          end
        end
      end
    end

    shared_examples_for "compares less than" do |_other_type|
      context "when other_type is :#{_other_type}" do
        let(:other_type) { _other_type }
        # set other_file and other_line to random stuff to prove they have no
        # effect
        let(:other_file) { random_alphas(file.length) }
        let(:other_line) { rand(4000) }

        it { is_expected.to eq(-1) }
      end
    end

    shared_examples_for "compares more than" do |_other_type|
      context "when other_type is :#{_other_type}" do
        let(:other_type) { _other_type }
        let(:other_file) { random_alphas(file.length) }
        let(:other_line) { rand(4000) }

        it { is_expected.to eq(1) }
      end
    end

    shared_examples_for "compares less than Markdown" do
      context "when other is a Markdown" do
        let(:other) { Danger::Markdown.new("hello world", file, line) }
        it { is_expected.to eq(-1) }
      end
    end

    context "when type is :error" do
      let(:type) { :error }

      context "when other is a Violation" do
        let(:other) { Danger::Violation.new("hello world", false, other_file, other_line, type: other_type) }
        let(:other_file) { file }
        let(:other_line) { line }

        include_examples "compares by file and line", :error
        include_examples "compares less than", :warning
        include_examples "compares less than", :message
      end

      include_examples "compares less than Markdown"
    end

    context "when type is :warning" do
      let(:type) { :warning }

      context "when other is a Violation" do
        let(:other) { Danger::Violation.new("hello world", false, other_file, other_line, type: other_type) }
        let(:other_file) { file }
        let(:other_line) { line }

        include_examples "compares more than", :error
        include_examples "compares by file and line", :warning
        include_examples "compares less than", :message
      end

      include_examples "compares less than Markdown"
    end

    context "when type is :message" do
      let(:type) { :message }

      context "when other is a Violation" do
        let(:other) { Danger::Violation.new("hello world", false, other_file, other_line, type: other_type) }
        let(:other_file) { file }
        let(:other_line) { line }

        include_examples "compares more than", :error
        include_examples "compares more than", :warning
        include_examples "compares by file and line", :message
      end

      include_examples "compares less than Markdown"
    end
  end
end
