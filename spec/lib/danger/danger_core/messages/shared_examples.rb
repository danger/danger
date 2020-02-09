# frozen_string_literal: true

# This helper method and the examples are used for the specs for #<=> on Markdown and Violation

def random_alphas(n)
  (0...n).map { ("a".."z").to_a[rand(26)] }
end

RSpec.shared_examples_for "compares by line" do
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
    let(:line) { rand(4000) }
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

RSpec.shared_examples_for "compares by file and line" do
  let(:other_line) { rand(4000) }
  context "when file is nil" do
    let(:file) { nil }

    context "when other_file is nil" do
      let(:other_file) { nil }
      it { is_expected.to eq(0) }
    end

    context "when other_file is not nil" do
      let(:other_file) { "world.txt" }
      it { is_expected.to eq(-1) }
    end
  end

  context "when file is not nil" do
    let(:file) { "hello.txt" }

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
