require "danger/ci_source/gitlab_ci"

RSpec.describe Danger::GitLabCI, host: :gitlab do
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

    describe ".determine_merge_request_id" do
      context "when CI_MERGE_REQUEST_ID present in envrionment" do
        it "returns CI_MERGE_REQUEST_ID" do
          expect(described_class.determine_merge_request_id({
            "CI_MERGE_REQUEST_ID" => 1
          })).to eq(1)
        end
      end

      context "when CI_COMMIT_SHA not present in envrionment" do
        it "returns 0" do
          expect(described_class.determine_merge_request_id({})).to eq(0)
        end
      end

      context "when CI_COMMIT_SHA present in envrionment" do
        it "uses gitlab api to find merge request id" do
          stub_merge_requests("merge_requests_response", "danger%2Fdanger")

          expect(described_class.determine_merge_request_id({
            "CI_PROJECT_ID" => "danger/danger",
            "CI_COMMIT_SHA" => "3333333333333333333333333333333333333333",
            "DANGER_GITLAB_API_TOKEN" => "a86e56d46ac78b"
          })).to eq(3)
        end
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
