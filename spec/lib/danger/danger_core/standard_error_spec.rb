RSpec.describe Danger::DSLError do
  let(:file_path) do
    Pathname.new(File.join("spec", "fixtures", "dangerfile_with_error"))
  end
  let(:description) do
    "Invalid `#{file_path.basename}` file: undefined local "\
    "variable or method `abc' for #<Danger::Dangerfile:1>"
  end
  let(:backtrace) do
    [
      "#{File.join('fake', 'path', 'dangerfile.rb')}:68:in `method_missing",
      "#{File.join('spec', 'fixtures', 'dangerfile_with_error')}:2:in `block in parse'",
      "#{File.join('fake', 'path', 'dangerfile.rb')}:199:in `eval"
    ]
  end

  subject { Danger::DSLError.new(description, file_path, backtrace) }

  describe "#message" do
    context "when danger version outdated" do
      before { allow(Danger).to receive(:danger_outdated?).and_return(0) }

      it "returns colored description with Dangerfile trace" do
        description =
          "[!] Invalid `dangerfile_with_error` file: undefined "\
          "local variable or method `abc' for #<Danger::Dangerfile:1>"\
          ". Updating the Danger gem might fix the issue. "\
          "Your Danger version: #{Danger::VERSION}, "\
          "latest Danger version: 0"

        expectation = [
          "\e[31m",
          description,
          "\e[0m",
          " #  from spec/fixtures/dangerfile_with_error:2",
          " #  -------------------------------------------",
          " #  # This will fail",
          " >  abc",
          " #  -------------------------------------------"
        ]

        expect(subject.message.split("\n")).to eq expectation
      end
    end

    context "when danger version latest" do
      before { allow(Danger).to receive(:danger_outdated?).and_return(false) }

      it "returns colored description with Dangerfile trace" do
        description =
          "[!] Invalid `dangerfile_with_error` file: undefined " \
          "local variable or method `abc' for #<Danger::Dangerfile:1>\e[0m"

        expectation = [
          "\e[31m",
          description,
          " #  from spec/fixtures/dangerfile_with_error:2",
          " #  -------------------------------------------",
          " #  # This will fail",
          " >  abc",
          " #  -------------------------------------------"
        ]

        expect(subject.message.split("\n")).to eq expectation
      end
    end
  end

  describe "#to_markdown" do
    context "when danger version outdated" do
      before { allow(Danger).to receive(:danger_outdated?).and_return(0) }

      it "returns description with Dangerfile trace as a escaped markdown" do
        description =
          "[!] Invalid `dangerfile_with_error` file: undefined " \
          "local variable or method `abc` for #\\<Danger::Dangerfile:1\\>" \
          ". Updating the Danger gem might fix the issue. "\
          "Your Danger version: #{Danger::VERSION}, "\
          "latest Danger version: 0"

        expectation = [
          "## Danger has errored",
          description,
          "",
          "```",
          " #  from spec/fixtures/dangerfile_with_error:2",
          " #  -------------------------------------------",
          " #  # This will fail",
          " >  abc",
          " #  -------------------------------------------",
          "```"
        ]

        subject.to_markdown.message.split("\n").each_with_index do |chunk, index|
          expect(chunk).to eq expectation[index]
        end

        expect(subject.to_markdown.message.split("\n")).to eq expectation
      end
    end

    context "when danger version latest" do
      before { allow(Danger).to receive(:danger_outdated?).and_return(false) }

      it "returns description with Dangerfile trace as a escaped markdown" do
        description =
          "[!] Invalid `dangerfile_with_error` file: undefined " \
          "local variable or method `abc` for #\\<Danger::Dangerfile:1\\>"

        expectation = [
          "## Danger has errored",
          description,
          "```",
          " #  from spec/fixtures/dangerfile_with_error:2",
          " #  -------------------------------------------",
          " #  # This will fail",
          " >  abc",
          " #  -------------------------------------------",
          "```"
        ]

        expect(subject.to_markdown.message.split("\n")).to eq expectation
      end
    end
  end

  after { allow(Danger).to receive(:danger_outdated?).and_call_original }
end
