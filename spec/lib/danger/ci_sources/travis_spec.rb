require "danger/ci_source/travis"

RSpec.describe Danger::Travis do
  let(:valid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
      "TRAVIS_PULL_REQUEST" => "800",
      "TRAVIS_REPO_SLUG" => "artsy/eigen"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when all Travis environment vars are set and Josh K says so" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    ["TRAVIS_PULL_REQUEST", "TRAVIS_REPO_SLUG"].each do |var|
      it "validates when `#{var}` is missing" do
        valid_env[var] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates when `#{var}` is empty" do
        valid_env[var] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end
    end

    it "does not validate when Josh K is not around" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when all Travis PR environment vars are set and Josh K says so" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    ["TRAVIS_PULL_REQUEST", "TRAVIS_REPO_SLUG"].each do |var|
      it "does not validate when `#{var}` is missing" do
        valid_env[var] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "does not validate when `#{var}` is empty" do
        valid_env[var] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    it "dost not validate when `TRAVIS_PULL_REQUEST` is `false`" do
      valid_env["TRAVIS_PULL_REQUEST"] = "false"
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `TRAVIS_PULL_REQUEST` is empty" do
      valid_env["TRAVIS_PULL_REQUEST"] = ""
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
