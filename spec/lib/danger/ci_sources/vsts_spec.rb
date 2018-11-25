require "danger/ci_source/vsts"

RSpec.describe Danger::VSTS do
  let(:valid_env) do
    {
      "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI" => "https://example.visualstudio.com",
      "BUILD_REPOSITORY_URI" => "https://example.visualstudio.com/_git/danger-test",
      "BUILD_SOURCEBRANCH" => "refs/pull/800/merge",
      "BUILD_REASON" => "PullRequest",
      "BUILD_REPOSITORY_NAME" => "danger-test",
      "SYSTEM_TEAMPROJECT" => "example",
      "BUILD_REPOSITORY_PROVIDER" => "TfsGit"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates even when `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI` is missing" do
      valid_env["SYSTEM_TEAMFOUNDATIONCOLLECTIONURI"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end

    it "validates even when `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI` is empty" do
      valid_env["SYSTEM_TEAMFOUNDATIONCOLLECTIONURI"] = ""
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end

    it "validates even when `BUILD_REPOSITORY_PROVIDER` is missing" do
      valid_env["BUILD_REPOSITORY_PROVIDER"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end

    it "validates even when `BUILD_REPOSITORY_PROVIDER` is empty" do
      valid_env["BUILD_REPOSITORY_PROVIDER"] = ""
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

    it "doesn't validate if `BUILD_SOURCEBRANCH` is missing" do
      valid_env["BUILD_SOURCEBRANCH"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `BUILD_SOURCEBRANCH` is the empty string" do
      valid_env["BUILD_SOURCEBRANCH"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate if `BUILD_REPOSITORY_URI` is missing" do
      valid_env["BUILD_REPOSITORY_URI"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `BUILD_REPOSITORY_URI` is the empty string" do
      valid_env["BUILD_REPOSITORY_URI"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate if `BUILD_REASON` is missing" do
      valid_env["BUILD_REASON"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `BUILD_REASON` is the empty string" do
      valid_env["BUILD_REASON"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate if `BUILD_REPOSITORY_NAME` is missing" do
      valid_env["BUILD_REPOSITORY_NAME"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if `BUILD_REPOSITORY_NAME` is the empty string" do
      valid_env["BUILD_REPOSITORY_NAME"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate when require env variables are not set" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("800")
    end

    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("example/danger-test")
    end

    it "sets the repo_url", host: :vsts do
      with_git_repo do
        expect(source.repo_url).to eq("https://example.visualstudio.com/_git/danger-test")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports VSTS" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::VSTS)
    end

    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
