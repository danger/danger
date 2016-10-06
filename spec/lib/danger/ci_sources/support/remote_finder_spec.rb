require "danger/ci_source/support/remote_finder"

RSpec.describe Danger::RemoteFinder do
  describe "#call" do
    it "returns repo slug from logs" do
      remote_logs = IO.read("spec/fixtures/ci_source/support/remote.log")
      finder = described_class.new("github.com", remote_logs)

      result = finder.call

      expect(result).to eq "danger/danger"
    end

    context "specify GitHub Enterprise URL" do
      it "returns repo slug from logs" do
        remote_logs = IO.read("spec/fixtures/ci_source/support/enterprise-remote.log")
        finder = described_class.new("artsyhub.com", remote_logs)

        result = finder.call

        expect(result).to eq "enterdanger/enterdanger"
      end
    end

    context "specify remote in https" do
      it "returns repo slug from logs" do
        remote_logs = IO.read("spec/fixtures/ci_source/support/https-remote.log")
        finder = described_class.new("github.com", remote_logs)

        result = finder.call

        expect(result).to eq "danger/danger"
      end
    end
  end
end
