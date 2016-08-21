require "danger/ci_source/teamcity"

describe Danger::TeamCity do
  let(:valid_env) do
    {
      "TEAMCITY_VERSION" => "42"
    }
  end

  let(:invalid_env) do
    {
    }
  end

  let(:source) { described_class.new(valid_env) }

  context "with GitHub" do
    before do
      valid_env["GITHUB_REPO_SLUG"] = "foo/bar"
      valid_env["GITHUB_PULL_REQUEST_ID"] = "42"
      valid_env["GITHUB_REPO_URL"] = "git@github.com:danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITHUB_PULL_REQUEST_ID` is missing" do
        valid_env["GITHUB_PULL_REQUEST_ID"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITHUB_PULL_REQUEST_ID` is empty" do
        valid_env["GITHUB_PULL_REQUEST_ID"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesnt validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn not validate if `GITHUB_PULL_REQUEST_ID` is missing" do
        valid_env["GITHUB_PULL_REQUEST_ID"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if pull_request_repo is the empty string" do
        valid_env["GITHUB_PULL_REQUEST_ID"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    describe "#new" do
      it "sets the pull_request_id" do
        expect(source.pull_request_id).to eq(42)
      end

      it "sets the repo_slug" do
        expect(source.repo_slug).to eq("foo/bar")
      end

      it "sets the repo_url" do
        expect(source.repo_url).to eq("git@github.com:danger/danger.git")
      end
    end
  end

  context "with GitLab" do
    before do
      valid_env["GITLAB_REPO_SLUG"] = "foo/bar"
      valid_env["GITLAB_PULL_REQUEST_ID"] = "42"
      valid_env["GITLAB_REPO_URL"] = "git@gitlab.com:danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITLAB_PULL_REQUEST_ID` is missing" do
        valid_env["GITLAB_PULL_REQUEST_ID"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITLAB_PULL_REQUEST_ID` is empty" do
        valid_env["GITLAB_PULL_REQUEST_ID"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesnt validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn not validate if `GITLAB_PULL_REQUEST_ID` is missing" do
        valid_env["GITLAB_PULL_REQUEST_ID"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if pull_request_repo is the empty string" do
        valid_env["GITLAB_PULL_REQUEST_ID"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    describe "#new" do
      it "sets the pull_request_id" do
        expect(source.pull_request_id).to eq(42)
      end

      it "sets the repo_slug" do
        expect(source.repo_slug).to eq("foo/bar")
      end

      it "sets the repo_url" do
        expect(source.repo_url).to eq("git@gitlab.com:danger/danger.git")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end

    it "supports GitLab" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitLab)
    end
  end
end
