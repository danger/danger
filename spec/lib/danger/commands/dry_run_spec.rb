require "danger/commands/dry_run"
require "open3"

RSpec.describe Danger::DryRun do
  context "prints help" do
    it "danger dry_run --help flag prints help" do
      stdout, = Open3.capture3("danger dry_run -h")
      expect(stdout).to include "Usage"
    end

    it "danger dry_run -h prints help" do
      stdout, = Open3.capture3("danger dry-run -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".options" do
    it "contains extra options for local command" do
      result = described_class.options

      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
    end
  end
end
