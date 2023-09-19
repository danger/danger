require "danger/ci_source/xcode_cloud"

RSpec.describe Danger::XcodeCloud do
  let(:valid_env) do
    {
      "CI_XCODEBUILD_ACTION" => "Any build action",
      "CI_PULL_REQUEST_NUMBER" => "999",
      "CI_PULL_REQUEST_SOURCE_REPO" => "danger/danger",
      "CI_PULL_REQUEST_HTML_URL" => "https://danger.systems"
    }
  end

  let(:invalid_env) do
    {
        "XCS_BOT_NAME" => "BuildaBot [danger/danger] PR #99"
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
  end

  describe ".validates_as_ci?" do
    it "validates when the required env variables are set" do
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
      expect(source.pull_request_id).to eq("999")
    end

    it "sets the repo_url", host: :github do
      with_git_repo(origin: "https://danger.systems") do
        expect(source.repo_url).to eq("https://danger.systems")
      end
    end
  end

  describe "supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end

    it "supports GitLab" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitLab)
    end

    it "supports BitbucketServer" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketServer)
    end

    it "supports BitbucketCloud" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketCloud)
    end
  end
end
