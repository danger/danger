require "danger/ci_source/codefresh"

RSpec.describe Danger::Codefresh do
  let(:valid_env) do
    {
      "CF_BUILD_ID" => "89",
      "CF_BUILD_URL" => "https://g.codefresh.io//build/qwerty123456",
      "CF_PULL_REQUEST_NUMBER" => "41",
      "CF_REPO_OWNER" => "Danger",
      "CF_REPO_NAME" => "danger",
      "CF_COMMIT_URL" => "https://github.com/danger/danger/commit/qwerty123456"
    }
  end
  let(:invalid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true"
    }
  end
  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "doesnt validate when require env variables are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required variables are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "doesn not validate if `CF_PULL_REQUEST_NUMBER` is missing" do
      valid_env["CF_PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `CF_PULL_REQUEST_NUMBER` is the empty string" do
      valid_env["CF_PULL_REQUEST_NUMBER"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".repo_slug" do
    it "sets the repo slug" do
      expect(source.repo_slug).to eq("danger/danger")
    end

    it "returns empty string for slug if no owner given" do
      valid_env["CF_REPO_OWNER"] = nil
      expect(source.repo_slug).to eq("")
    end

    it "returns empty string for slug if no name given" do
      valid_env["CF_REPO_NAME"] = nil
      expect(source.repo_slug).to eq("")
    end
  end

  describe ".repo_url" do
    it "sets the pull request url" do
      expect(source.repo_url).to eq("https://github.com/danger/danger")
    end

    it "returns empty string if no commit URL given" do
      valid_env["CF_COMMIT_URL"] = nil
      expect(source.repo_url).to eq("")
    end
  end

  describe "#new" do
    it "sets the pull request id" do
      expect(source.pull_request_id).to eq("41")
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
