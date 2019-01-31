require "danger/ci_source/bitbucket_pipeline"

RSpec.describe Danger::BitbucketPipeline\ do
  let(:valid_env) do
    {
      "BITBUCKET_BUILD_NUMBER" => "2",
      "BITBUCKET_PR_ID" => "4",
      "BITBUCKET_REPO_SLUG" => "foobar"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env["BITBUCKET_BUILD_NUMBER"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env["BITBUCKET_PR_ID"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".new" do
    it "sets the repository slug" do
      expect(source.repo_slug).to eq("foobar")
      expect(source.pull_request_id).to eq("4")
    end
  end
end
