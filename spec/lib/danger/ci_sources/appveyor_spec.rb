require "danger/ci_source/appveyor"

RSpec.describe Danger::AppVeyor do
  let(:valid_env) do
    {
      "APPVEYOR_PULL_REQUEST_NUMBER" => "2",
      "APPVEYOR" => "true",
      "APPVEYOR_REPO_NAME" => "artsy/eigen"
    }
  end

  let(:invalid_env) do
    {
      "BITRISE_IO" => "true"
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
      valid_env["APPVEYOR_PULL_REQUEST_NUMBER"] = nil
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
      valid_env["APPVEYOR_PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end
  end

  describe "#new" do
    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("artsy/eigen")
    end

    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("2")
    end

    it "sets the repo_url", host: :github do
      with_git_repo(origin: "git@github.com:artsy/eigen") do
        expect(source.repo_url).to eq("git@github.com:artsy/eigen")
      end
    end
  end
end
