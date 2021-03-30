# require "danger/ci_source/bamboo"

RSpec.describe Danger::Bamboo do
  let(:valid_env) do
    {
        "bamboo_buildKey" => "1",
        "bamboo_repository_pr_key" => "33",
        "bamboo_planRepository_repositoryUrl" => "git@github.com:danger/danger.git"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env.delete "bamboo_buildKey"
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when the required pull request is not set" do
      valid_env["bamboo_repository_pr_key"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate when the required repo url is not set" do
      valid_env["bamboo_planRepository_repositoryUrl"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".new" do
    it "sets the required attributes" do
      expect(source.repo_slug).to eq("danger/danger")
      expect(source.pull_request_id).to eq("33")
      expect(source.repo_url).to eq("git@github.com:danger/danger.git")
    end

    it "supports Bitbucket Server" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketServer)
    end
  end
end
