require "danger/commands/pr"

RSpec.describe Danger::PR do
  describe ".summary" do
    it "returns the summary for PR command" do
      result = described_class.summary

      expect(result).to eq "Run the Dangerfile against Pull Requests (works with forks, too)."
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
    end
  end

  context "default options" do
    it "pr url is nil and clear_http_cache defaults to false" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@pr_url" => nil,
        "@clear_http_cache" => false
      )
    end
  end
end
