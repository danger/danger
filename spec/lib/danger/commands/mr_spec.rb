# frozen_string_literal: true

require "danger/commands/mr"
require "open3"

RSpec.describe Danger::MR do
  context "prints help" do
    it "danger mr --help flag prints help" do
      stdout, = Open3.capture3("danger mr -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".summary" do
    it "returns the summary for MR command" do
      result = described_class.summary

      expect(result).to eq "Run the Dangerfile locally against GitLab Merge Requests. Does not post to the MR. Usage: danger mr <URL>"
    end
  end

  context "takes the first argument as MR URL" do
    it "works" do
      argv = CLAide::ARGV.new(["https://gitlab.com/gitlab-org/gitlab-ce/-/merge_requests/42"])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@mr_url" => "https://gitlab.com/gitlab-org/gitlab-ce/-/merge_requests/42"
      )
    end
  end

  describe ".options" do
    it "contains extra options for MR command" do
      result = described_class.options

      expect(result).to include ["--clear-http-cache", "Clear the local http cache before running Danger locally."]
      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
      expect(result).to include ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"]
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
    it "mr url is nil and clear_http_cache defaults to false" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result).to have_instance_variables(
        "@mr_url" => nil,
        "@clear_http_cache" => false
      )
    end
  end

  context "#run" do
    let(:env_double) { instance_double("Danger::EnvironmentManager") }
    let(:request_source_double) { instance_double("Danger::RequestSources::RequestSource") }

    it "does not post to the mr" do
      allow(Danger::EnvironmentManager).to receive(:new).and_return(env_double)
      allow(env_double).to receive(:request_source).and_return(request_source_double)
      allow(request_source_double).to receive(:update_pull_request!)

      argv = CLAide::ARGV.new(["https://gitlab.com/gitlab-org/gitlab-ce/-/merge_requests/42"])

      result = described_class.new(argv)
      expect(request_source_double).not_to have_received(:update_pull_request!)
    end
  end
end
