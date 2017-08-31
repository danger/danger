require "danger/ci_source/vsts"

RSpec.describe Danger::VSTS do
  let(:valid_env) do
    {
      "BUILD_BUILDID" => "5",
      "SYSTEM_PULLREQUEST_PULLREQUESTID" => "800",
      "SYSTEM_TEAMPROJECT" => "artsy",
      "BUILD_REPOSITORY_URI" => "https://test.visualstudio.com/_git/eigen"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates even when `BUILD_BUILDID` is missing" do
      valid_env["BUILD_BUILDID"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end

    it "validates even when `BUILD_BUILDID` is empty" do
      valid_env["BUILD_BUILDID"] = ""
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end

    it "doesn't validate when require env variables are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required variables are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "doesn't validate if `SYSTEM_PULLREQUEST_PULLREQUESTID` is missing" do
      valid_env["SYSTEM_PULLREQUEST_PULLREQUESTID"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `SYSTEM_PULLREQUEST_PULLREQUESTID` is the empty string" do
      valid_env["SYSTEM_PULLREQUEST_PULLREQUESTID"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe "#new" do
    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("800")
    end

    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("artsy/eigen")
    end

    it "sets the repo_url", host: :vsts do
      with_git_repo do
        expect(source.repo_url).to eq("https://test.visualstudio.com/_git/eigen")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports VSTS" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::VSTS)
    end
  end
end
