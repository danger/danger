require "danger/commands/local"
require "open3"

RSpec.describe Danger::Local do
  context "prints help" do
    it "danger local --help flag prints help" do
      stdout, = Open3.capture3("danger local -h")
      expect(stdout).to include "Usage"
    end

    it "danger local -h prints help" do
      stdout, = Open3.capture3("danger local -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".options" do
    it "contains extra options for local command" do
      result = described_class.options

      expect(result).to include ["--use-merged-pr=[#id]", "The ID of an already merged PR inside your history to use as a reference for the local run."]
      expect(result).to include ["--clear-http-cache", "Clear the local http cache before running Danger locally."]
      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
    end
  end

  context "default options" do
    it "pr number is nil and clear_http_cache defaults to false" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result.instance_variable_get(:"@pr_num")).to eq nil
      expect(result.instance_variable_get(:"@clear_http_cache")).to eq false
    end
  end
end
