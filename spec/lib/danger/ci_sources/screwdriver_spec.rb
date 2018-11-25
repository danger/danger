# require "danger/ci_source/screwdriver"

RSpec.describe Danger::Screwdriver do
  let(:valid_env) do
    {
        "SCREWDRIVER" => "true",
        "SD_PULL_REQUEST" => "42",
        "SCM_URL" => "git@github.com:danger/danger.git#branch"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env.delete "SCREWDRIVER"
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when the required pull request is not set" do
      valid_env["SD_PULL_REQUEST"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate when the required repo url is not set" do
      valid_env["SCM_URL"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".new" do
    it "sets the required attributes" do
      expect(source.repo_slug).to eq("danger/danger")
      expect(source.pull_request_id).to eq("42")
      expect(source.repo_url).to eq("git@github.com:danger/danger.git")
    end
  end
end
