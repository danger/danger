require "danger/ci_source/buddybuild"

RSpec.describe Danger::Buddybuild do
  let(:valid_env) do
    {
      "BUDDYBUILD_BUILD_ID" => "595be087b095370001d8e0b3",
      "BUDDYBUILD_PULL_REQUEST" => "4",
      "BUDDYBUILD_REPO_SLUG" => "palleas/Batman"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env["BUDDYBUILD_BUILD_ID"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the required env vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validate when the required env vars are not set" do
      valid_env["BUDDYBUILD_PULL_REQUEST"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe ".new" do
    it "sets the repository slug" do
      expect(source.repo_slug).to eq("palleas/Batman")
      expect(source.pull_request_id).to eq("4")
    end
  end
end
