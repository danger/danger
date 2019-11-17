require "danger/ci_source/travis"

RSpec.describe Danger::Semaphore do
  let(:valid_env) do
    {
      "SEMAPHORE" => "true",
      "SEMAPHORE_GIT_PR_NUMBER" => "800",
      "SEMAPHORE_GIT_REPO_SLUG" => "artsy/eigen",
      "SEMAPHORE_GIT_URL" => "git@github.com:artsy/eigen"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci" do
    it "validates when the expected valid_env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates when `SEMAPHORE_GIT_PR_NUMBER` is missing" do
      valid_env["SEMAPHORE_GIT_PR_NUMBER"] = nil
      valid_env["PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates when `SEMAPHORE_GIT_REPO_SLUG` is missing" do
      valid_env["SEMAPHORE_GIT_REPO_SLUG"] = nil
      valid_env["SEMAPHORE_REPO_SLUG"] = nil
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

    it "does not validate if `SEMAPHORE_GIT_PR_NUMBER` is missing" do
      valid_env["SEMAPHORE_GIT_PR_NUMBER"] = nil
      valid_env["PULL_REQUEST_NUMBER"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `SEMAPHORE_GIT_PR_NUMBER` is empty" do
      valid_env["SEMAPHORE_GIT_PR_NUMBER"] = ""
      valid_env["PULL_REQUEST_NUMBER"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `SEMAPHORE_GIT_REPO_SLUG` is missing" do
      valid_env["SEMAPHORE_GIT_REPO_SLUG"] = nil
      valid_env["SEMAPHORE_REPO_SLUG"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `SEMAPHORE_GIT_REPO_SLUG` is empty" do
      valid_env["SEMAPHORE_GIT_REPO_SLUG"] = ""
      valid_env["SEMAPHORE_REPO_SLUG"] = ""
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

    it "sets the repo_url", host: :github do
      with_git_repo do
        expect(source.repo_url).to eq("git@github.com:artsy/eigen")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
