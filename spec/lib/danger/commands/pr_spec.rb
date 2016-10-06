require "danger/commands/pr"

RSpec.describe Danger::PR do
  describe ".summary" do
    it "returns the summary for PR command" do
      result = described_class.summary

      expect(result).to eq "Run the Dangerfile against Pull Requests (works with forks, too)."
    end
  end

  describe ".options" do
    it "contains extra options for PR command" do
      result = described_class.options

      expect(result).to include ["--use-pr=[#id]", "The URL of the Pull Request for the command to run."]
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

    it "@pr_url can be set via --use-pr option" do
      argv = CLAide::ARGV.new(["--use-pr=https://github.com/danger/danger/pull/615"])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@pr_url" => "https://github.com/danger/danger/pull/615"
      )
    end
  end
end
