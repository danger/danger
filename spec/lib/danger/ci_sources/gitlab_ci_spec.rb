require "danger/ci_source/gitlab_ci"

describe Danger::GitLabCI, host: :gitlab do
  context "valid envrionment" do
    let(:gitlab_env) do
      {
        "GITLAB_CI" => "1",
        "CI_MERGE_REQUEST_ID" => "28493",
        "CI_PROJECT_ID" => "danger/danger"
      }
    end

    let(:ci_source) do
      described_class.new(gitlab_env)
    end

    describe ".validates_as_ci?" do
      it "is valid" do
        expect(described_class.validates_as_ci?(gitlab_env)).to be(true)
      end
    end

    describe ".validates_as_pr?" do
      it "is valid" do
        expect(described_class.validates_as_pr?(gitlab_env)).to be(true)
      end
    end

    describe "#supported_request_sources" do
      it "it is gitlab" do
        expect(ci_source.supported_request_sources).to eq([Danger::RequestSources::GitLab])
      end
    end

    describe "#initialize" do
      it "sets the repo_slug" do
        expect(ci_source.repo_slug).to eq("danger/danger")
      end

      it "sets the pull_request_id" do
        expect(ci_source.pull_request_id).to eq("28493")
      end
    end
  end
end
