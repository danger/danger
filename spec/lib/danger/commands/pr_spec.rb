require "danger/commands/pr"
require "open3"

RSpec.describe Danger::PR do
  context "prints help" do
    it "danger pr --help flag prints help" do
      stdout, = Open3.capture3("danger pr -h")
      expect(stdout).to include "Usage"
    end

    it "danger pr -h prints help" do
      stdout, = Open3.capture3("danger pr -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".summary" do
    it "returns the summary for PR command" do
      result = described_class.summary

      expect(result).to eq "Run the Dangerfile locally against Pull Requests (works with forks, too). Does not post to the PR. Usage: danger pr <URL>"
    end
  end

  context "takes the first argument as PR URL" do
    it "works" do
      argv = CLAide::ARGV.new(["https://github.com/artsy/eigen/pull/1899"])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@pr_url" => "https://github.com/artsy/eigen/pull/1899"
      )
    end
  end

  describe ".options" do
    it "contains extra options for PR command" do
      result = described_class.options

      expect(result).to include ["--clear-http-cache", "Clear the local http cache before running Danger locally."]
      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
      expect(result).to include ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"]
      expect(result).to include ["--verify-ssl", "Verify SSL in Octokit"]
    end

    it "dangerfile can be set" do
      argv = CLAide::ARGV.new(["--dangerfile=/Users/Orta/Dangerfile"])
      allow(File).to receive(:exist?) { true }

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@dangerfile_path" => "/Users/Orta/Dangerfile"
      )
    end
  end

  context "default options" do
    it "pr url is nil, clear_http_cache defaults to false and verify-ssl defaults to true" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@pr_url" => nil,
        "@clear_http_cache" => false,
        "@verify_ssl" => true
      )
    end
  end
end
