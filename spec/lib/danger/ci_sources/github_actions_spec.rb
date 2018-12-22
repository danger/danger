require "danger/ci_source/github_actions"

RSpec.describe Danger::GitHubActions do
  let(:valid_env) do
    {
      "GITHUB_ACTION" => "name_of_action",
      "GITHUB_EVENT_NAME" => "pull_request",
      "GITHUB_REPOSITORY" => "danger/danger",
      "GITHUB_EVENT_PATH" => File.expand_path("../../../../fixtures/ci_source/pull_request_event.json", __FILE__ )
    }
  end

  let(:invalid_env) do
    {
    }
  end

  let(:source) { described_class.new(valid_env) }

  context "with GitHub" do
    describe ".validates_as_ci?" do
      it "validates when required env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITHUB_ACTION` is missing" do
        valid_env["GITHUB_ACTION"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `GITHUB_ACTION` is empty" do
        valid_env["GITHUB_ACTION"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesn't validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates if `GITHUB_EVENT_NAME` is 'pull_request" do
        valid_env["GITHUB_EVENT_NAME"] = "pull_request"
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn't validate if `GITHUB_EVENT_NAME` is 'push'" do
        valid_env["GITHUB_EVENT_NAME"] = "push"
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate if `GITHUB_EVENT_NAME` is missing" do
        valid_env["GITHUB_EVENT_NAME"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug" do
        expect(source.repo_slug).to eq("danger/danger")
      end
    end

    describe "pull request id" do
      it "get out a pull request id" do
        expect(source.pull_request_id).to eq 1
      end
    end

    describe "repo url" do
      it "get out a repo url" do
        expect(source.repo_url).to eq "https://github.com/Codertocat/Hello-World.git"
      end
    end

    describe "without DANGER_GITHUB_API_TOKEN" do
      it "override by GITHUB_TOKEN if GITHUB_TOKEN is not empty" do
        valid_env["GITHUB_TOKEN"] = "github_token"
        source
        expect(valid_env["DANGER_GITHUB_API_TOKEN"]).to eq("github_token")
      end

      it "doesn't override if DANGER_GITHUB_API_TOKEN is not empty" do
        valid_env["DANGER_GITHUB_API_TOKEN"] = "danger_github_api_token"
        valid_env["GITHUB_TOKEN"] = "github_token"
        source
        expect(valid_env["DANGER_GITHUB_API_TOKEN"]).to eq("danger_github_api_token")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
