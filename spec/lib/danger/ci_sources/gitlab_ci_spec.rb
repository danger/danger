require "danger/ci_source/gitlab_ci"

RSpec.describe Danger::GitLabCI, host: :gitlab do
  context "valid environment" do
    let(:env) { stub_env.merge("CI_MERGE_REQUEST_IID" => 28_493) }

    let(:ci_source) do
      described_class.new(env)
    end

    describe ".validates_as_ci?" do
      it "is valid" do
        expect(described_class.validates_as_ci?(env)).to be(true)
      end
    end

    describe ".validates_as_pr?" do
      it "is valid" do
        expect(described_class.validates_as_pr?(env)).to be(true)
      end
    end

    describe ".determine_merge_request_id" do
      context "when CI_MERGE_REQUEST_IID present in environment" do
        it "returns CI_MERGE_REQUEST_IID" do
          expect(described_class.determine_merge_request_id({
            "CI_MERGE_REQUEST_IID" => 1
          })).to eq(1)
        end
      end

      context "when CI_COMMIT_SHA not present in environment" do
        it "returns 0" do
          expect(described_class.determine_merge_request_id({})).to eq(0)
        end
      end

      context "when CI_COMMIT_SHA present in environment" do
        it "uses gitlab api to find merge request id" do
          stub_merge_requests("merge_requests_response", "k0nserv%2Fdanger-test")

          expect(described_class.determine_merge_request_id({
            "CI_MERGE_REQUEST_PROJECT_PATH" => "k0nserv/danger-test",
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
        expect(ci_source.repo_slug).to eq("k0nserv/danger-test")
      end
    end

    describe "#project_url" do
      it "sets the project_url" do
        expect(ci_source.project_url).to eq(env["CI_MERGE_REQUEST_PROJECT_URL"])
      end
    end

    describe "#pull_request_id" do
      it "sets the pull_request_id" do
        expect(ci_source.pull_request_id).to eq(env["CI_MERGE_REQUEST_IID"])
      end
    end
  end
  
  context "valid environment on GitLab < 11.6" do
    let(:env) { stub_env_pre_11_6.merge("CI_MERGE_REQUEST_IID" => 28_493) }

    let(:ci_source) do
      described_class.new(env)
    end

    describe "#initialize" do
      it "sets the repo_slug" do
        expect(ci_source.repo_slug).to eq("k0nserv/danger-test")
      end
    end
    
    describe "#project_url" do
      it "sets the project_url" do
        expect(ci_source.project_url).to eq(env["CI_PROJECT_URL"])
      end
    end

  end
end
