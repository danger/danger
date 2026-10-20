# frozen_string_literal: true

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

  context "#run" do
    let(:env_double) { instance_double("Danger::EnvironmentManager") }
    let(:request_source_double) { instance_double("Danger::RequestSources::RequestSource") }

    it "does not post to the pr" do
      allow(Danger::EnvironmentManager).to receive(:new).and_return(env_double)
      allow(env_double).to receive(:request_source).and_return(request_source_double)
      allow(request_source_double).to receive(:update_pull_request!)

      argv = CLAide::ARGV.new(["https://github.com/danger/danger/pull/1366"])

      result = described_class.new(argv)
      expect(request_source_double).not_to have_received(:update_pull_request!)
    end

    describe "non-posting CI execution" do
      let(:arguments) { [] }
      let(:failed) { true }
      let(:command) { described_class.new(CLAide::ARGV.new(["https://github.com/danger/danger/pull/1558"] + arguments)) }
      let(:environment) { instance_double(Danger::EnvironmentManager) }
      let(:dangerfile) { instance_double(Danger::Dangerfile, run: failed) }
      let(:setup) { instance_double(Danger::LocalSetup) }

      before do
        stub_const("ENV", {})
        allow(command).to receive(:configure_octokit)
        allow(Danger::EnvironmentManager).to receive(:new).and_return(environment)
        allow(Danger::Dangerfile).to receive(:new).and_return(dangerfile)
        allow(Danger::LocalSetup).to receive(:new).and_return(setup)
        allow(setup).to receive(:setup).and_yield
      end

      it "runs with PR context without posting results and preserves the default exit behavior" do
        command.run

        expect(ENV["LOCAL_GIT_PR_URL"]).to eq("https://github.com/danger/danger/pull/1558")
        expect(dangerfile).to have_received(:run).with(anything, anything, "Dangerfile", nil, nil, nil, false)
      end

      context "when failing on errors is enabled" do
        let(:arguments) { ["--fail-on-errors=true"] }

        it "exits unsuccessfully when the Dangerfile reports errors" do
          expect { command.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        end

        context "when there are no errors" do
          let(:failed) { false }

          it "does not fail" do
            expect { command.run }.not_to raise_error
          end
        end
      end

      context "when failing on errors is explicitly disabled" do
        let(:arguments) { ["--fail-on-errors=false"] }

        it "preserves the successful exit behavior" do
          expect { command.run }.not_to raise_error
        end
      end
    end
  end
end
