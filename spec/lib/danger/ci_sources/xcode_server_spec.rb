require "danger/ci_source/xcode_server"

RSpec.describe Danger::XcodeServer do
  let(:valid_env) do
    {
      "XCS_BOT_NAME" => "BuildaBot [danger/danger] PR #17"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_pr?" do
    it "validates when the required env variables are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when XCS_BOT_NAME does not contain BuildaBot" do
      valid_env["XCS_BOT_NAME"] = "[danger/danger] PR #17"
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate when the required env variables are not set" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end
  end

  describe ".validates_as_ci?" do
    it "validates when the required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates when `XCS_BOT_NAME` does not contain `BuildaBot`" do
      valid_env["XCS_BOT_NAME"] = "[danger/danger] PR #17"
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env variables are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("danger/danger")
    end

    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("17")
    end

    it "sets the repo_url", host: :github do
      with_git_repo(origin: "git@github.com:artsy/eigen") do
        expect(source.repo_url).to eq("git@github.com:artsy/eigen")
      end
    end
  end

  describe "supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end

    it "supports BitbucketServer" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketServer)
    end

    it "supports BitbucketCloud" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketCloud)
    end
  end
end
