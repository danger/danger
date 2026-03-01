require "danger/ci_source/surf"

RSpec.describe Danger::Surf do
  let(:valid_env) do
    {
      "SURF_REPO" => "https://github.com/surf-build/surf",
      "SURF_NWO" => "surf-build/surf",
      "SURF_PR_NUM" => "29"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when the expected valid_env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validated when some expected valid_env variables are missing" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when the expected valid_env variables are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    it "does not validated when some expected valid_env variables are missing" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("29")
    end

    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("surf-build/surf")
    end

    it "sets the repo_url" do
      expect(source.repo_url).to eq("https://github.com/surf-build/surf")
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
