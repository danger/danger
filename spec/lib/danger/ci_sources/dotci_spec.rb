require "danger/ci_source/circle"

RSpec.describe Danger::DotCi do
  let(:valid_env) do
    {
      "DOTCI" => "true",
      "DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL" => "git@github.com:danger/danger.git",
      "DOTCI_PULL_REQUEST" => "1234"
    }
  end

  let(:invalid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  context "with GitHub" do
    before do
      valid_env["DOTCI_PULL_REQUEST"] = "1234"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `DOTCI_PULL_REQUEST` is missing" do
        valid_env["DOTCI_PULL_REQUEST"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `DOTCI_PULL_REQUEST` is empty" do
        valid_env["DOTCI_PULL_REQUEST"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesn't validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        valid_env["DOTCI_PULL_REQUEST"] = "1234"
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn't validate if `DOTCI_PULL_REQUEST` is missing" do
        valid_env["DOTCI_PULL_REQUEST"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug from a git+ssh repo" do
        expect(source.repo_slug).to eq("danger/danger")
      end

      it "gets out a repo slug from a https repo" do
        valid_env["DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL"] = "https://gitlab.com/danger/danger.git"

        expect(source.repo_slug).to eq("danger/danger")
      end

      it "get out a repo slug from a repo with dot in name" do
        valid_env["DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL"] = "https://gitlab.com/danger/danger.test.git"

        expect(source.repo_slug).to eq("danger/danger.test")
      end

      it "get out a repo slug from a repo with .git in name" do
        valid_env["DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL"] = "https://gitlab.com/danger/danger.git.git"

        expect(source.repo_slug).to eq("danger/danger.git")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
