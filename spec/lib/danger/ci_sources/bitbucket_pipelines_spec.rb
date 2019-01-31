require "danger/ci_source/bitbucket_pipelines"

RSpec.describe Danger::BitbucketPipelines do
  let(:valid_env) do
    {
      "BITBUCKET_BUILD_NUMBER" => "2",
      "BITBUCKET_PR_ID" => "4",
      "BITBUCKET_REPO_OWNER" => "foo",
      "BITBUCKET_REPO_SLUG" => "bar"
    }
  end

  let(:invalid_env) do
    {
      "BITRISE_IO" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end
  end

  describe ".new" do
    it "sets the repository slug" do
      expect(source.repo_slug).to eq("foo/bar")
      expect(source.pull_request_id).to eq("4")
    end
  end
end
