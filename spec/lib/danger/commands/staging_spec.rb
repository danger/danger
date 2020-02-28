require "danger/commands/staging"
require "open3"

RSpec.describe Danger::Staging do
  context "prints help" do
    it "danger staging --help flag prints help" do
      stdout, = Open3.capture3("danger staging -h")
      expect(stdout).to include "Usage"
    end

    it "danger staging -h prints help" do
      stdout, = Open3.capture3("danger staging -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".options" do
    it "contains extra options for staging command" do
      result = described_class.options

      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
    end
  end
end
