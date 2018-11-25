require "danger/commands/runner"
require "danger/danger_core/executor"

RSpec.describe Danger::Runner do
  context "without Dangerfile" do
    it "raises error" do
      argv = CLAide::ARGV.new([])

      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          runner = described_class.new(argv)
          expect { runner.validate! }.to raise_error(StandardError, /Could not find a Dangerfile./)
        end
      end
    end
  end

  context "default options" do
    it "sets instance variables accrodingly" do
      argv = CLAide::ARGV.new([])

      runner = described_class.new(argv)
      ui = runner.instance_variable_get(:"@cork")

      expect(runner).to have_instance_variables(
        "@dangerfile_path" => "Dangerfile",
        "@base" => nil,
        "@head" => nil,
        "@fail_on_errors" => false,
        "@danger_id" => "danger",
        "@new_comment" => nil
      )
      expect(ui).to be_a Cork::Board
      expect(ui).to have_instance_variables(
        "@silent" => false,
        "@verbose" => false
      )
    end
  end

  context "colored output" do
    before do
      expect(Danger::Executor).to receive(:new) { executor }
      expect(executor).to receive(:run) { "Colored message".red }
    end
    after { Colored2.enable! } # reset to expected value to avoid false positives in other tests

    let(:argv) { [] }
    let(:runner) { described_class.new(CLAide::ARGV.new(argv)) }
    let(:executor) { double("Executor") }

    it "adds ansi codes to strings" do
      expect(runner.run).to eq "\e[31mColored message\e[0m"
    end

    context "when no-ansi is specified" do
      let(:argv) { ["--no-ansi"] }

      it "does not add ansi codes to strings" do
        expect(runner.run).to eq "Colored message"
      end
    end
  end

  describe "#run" do
    it "invokes Executor" do
      argv = CLAide::ARGV.new([])
      runner = described_class.new(argv)
      executor = double("Executor")

      expect(Danger::Executor).to receive(:new) { executor }
      expect(executor).to receive(:run).with(
        base: nil,
        head: nil,
        dangerfile_path: "Dangerfile",
        danger_id: "danger",
        new_comment: nil,
        fail_on_errors: false,
        remove_previous_comments: nil
      )

      runner.run
    end

    context "with custom CLI options passed in" do
      before { IO.write("MyDangerfile", "") }

      it "overrides default options" do
        argv = CLAide::ARGV.new(
          [
            "--base=my-base",
            "--head=my-head",
            "--dangerfile=MyDangerfile",
            "--danger_id=my-danger-id",
            "--new-comment",
            "--fail-on-errors=true",
            "--remove-previous-comments"
          ]
        )
        runner = described_class.new(argv)
        executor = double("Executor")

        expect(Danger::Executor).to receive(:new) { executor }
        expect(executor).to receive(:run).with(
          base: "my-base",
          head: "my-head",
          dangerfile_path: "MyDangerfile",
          danger_id: "my-danger-id",
          new_comment: true,
          fail_on_errors: "true",
          remove_previous_comments: true
        )

        runner.run
      end

      after { FileUtils.rm("MyDangerfile") }
    end
  end
end
