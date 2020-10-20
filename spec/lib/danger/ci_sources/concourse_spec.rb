require "danger/ci_source/concourse"

RSpec.describe Danger::Concourse do
  let(:valid_env) do
    {
      "CONCOURSE" => "true",
      "PULL_REQUEST_ID" => "800",
      "REPO_SLUG" => "artsy/eigen"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when all Concourse environment vars are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    ["PULL_REQUEST_ID", "REPO_SLUG"].each do |var|
      it "validates when `#{var}` is missing" do
        valid_env[var] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates when `#{var}` is empty" do
        valid_env[var] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end
    end
  end

  describe ".validates_as_pr?" do
    it "validates when all Concourse PR environment vars are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    ["PULL_REQUEST_ID", "REPO_SLUG"].each do |var|
      it "does not validate when `#{var}` is missing" do
        valid_env[var] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "does not validate when `#{var}` is empty" do
        valid_env[var] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    it "dost not validate when `PULL_REQUEST_ID` is `false`" do
      valid_env["PULL_REQUEST_ID"] = "false"
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `PULL_REQUEST_ID` is empty" do
      valid_env["PULL_REQUEST_ID"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "does not validate if `PULL_REQUEST_ID` is not a int" do
      valid_env["PULL_REQUEST_ID"] = "pulls"
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
