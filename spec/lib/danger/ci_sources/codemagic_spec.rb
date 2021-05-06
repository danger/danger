require "danger/ci_source/codemagic"

RSpec.describe Danger::Codemagic do
  let(:valid_env) do
    {
      "FCI_PULL_REQUEST_NUMBER" => "4",
      "FCI_PROJECT_ID" => "1234",
      "FCI_REPO_SLUG" => "konsti/Batman"
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

    it "does not validate when the required env variables are not set" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end

    it "does not validate when there isn't a PR" do
      valid_env["FCI_PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".validates_as_ci?" do
    it "validates when the required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env variables are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end

    it "validates even when there is no PR" do
      valid_env["FCI_PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end
  end

  describe "#new" do
    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("konsti/Batman")
    end

    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("4")
    end

  end

  describe "supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
    it "supports GitLab" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitLab)
    end
    it "supports BitBucket Cloud" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketCloud)
    end
    it "supports BitBucket Server" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketServer)
    end
  end
end
