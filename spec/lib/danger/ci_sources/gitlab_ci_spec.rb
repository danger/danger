require "danger/ci_source/gitlab_ci"

RSpec.describe Danger::GitLabCI, host: :gitlab do
  context "valid environment" do
    let(:env) { stub_env }
    let(:ci_source) do
      described_class.new(env)
    end

    describe "#supported_request_sources" do
      it "it is gitlab" do
        expect(
          ci_source.supported_request_sources
        ).to eq([Danger::RequestSources::GitHub,
                 Danger::RequestSources::GitLab])
      end
    end

    context "given PR made on gitlab hosted repository" do
      let(:env) { stub_env.merge("CI_MERGE_REQUEST_IID" => 28_493) }

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

      describe ".determine_pull_or_merge_request_id" do
        context "when CI_MERGE_REQUEST_IID present in environment" do
          it "returns CI_MERGE_REQUEST_IID" do
            expect(described_class.determine_pull_or_merge_request_id({
              "CI_MERGE_REQUEST_IID" => 1
            })).to eq(1)
          end
        end

        context "when CI_COMMIT_SHA not present in environment" do
          it "returns 0" do
            expect(
              described_class.determine_pull_or_merge_request_id({})
            ).to eq(0)
          end
        end

        context "when CI_COMMIT_SHA present in environment" do
          context "before version 10.7" do
            it "uses gitlab api to find merge request id" do
              stub_version("10.6.4")
              stub_merge_requests("merge_requests_response", "k0nserv%2Fdanger-test")

              expect(described_class.determine_pull_or_merge_request_id({
                "CI_MERGE_REQUEST_PROJECT_PATH" => "k0nserv/danger-test",
                "CI_COMMIT_SHA" => "3333333333333333333333333333333333333333",
                "DANGER_GITLAB_API_TOKEN" => "a86e56d46ac78b"
              })).to eq(3)
            end
          end
          context "version 10.7 or later" do
            it "uses gitlab api to find merge request id" do
              #Arbitrary version, as tested manually, including text components to exercise the version comparison
              stub_version("11.10.0-rc6-ee")
              commit_sha = "3333333333333333333333333333333333333333"
              stub_commit_merge_requests("commit_merge_requests", "k0nserv%2Fdanger-test", commit_sha)

              expect(described_class.determine_pull_or_merge_request_id({
                "CI_MERGE_REQUEST_PROJECT_PATH" => "k0nserv/danger-test",
                "CI_COMMIT_SHA" => commit_sha,
                "DANGER_GITLAB_API_TOKEN" => "a86e56d46ac78b"
              })).to eq(1)
            end
          end
        end
      end

      describe "#initialize" do
        it "sets the repo_slug" do
          expect(ci_source.repo_slug).to eq("k0nserv/danger-test")
        end
      end

      describe "#pull_request_id" do
        it "sets the pull_request_id" do
          expect(ci_source.pull_request_id).to eq(env["CI_MERGE_REQUEST_IID"])
        end
      end
    end

    context "given PR made on github hosted repository" do
      let(:pr_num) { '24' }
      let(:repo_url) { 'https://github.com/procore/blueprinter' }
      let(:repo_slug) { 'procore/blueprinter' }
      let(:env) do
        stub_env.merge(
          {
            "CI_EXTERNAL_PULL_REQUEST_IID" => pr_num,
            "DANGER_PROJECT_REPO_URL" => repo_url
          }
        )
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

      describe ".determine_pull_or_merge_request_id" do
        context "when CI_MERGE_REQUEST_IID present in environment" do
          it "returns CI_MERGE_REQUEST_IID" do
            expect(described_class.determine_pull_or_merge_request_id(env)).to eq(pr_num)
          end
        end
      end

      describe "#initialize" do
        it "sets the repo_slug" do
          expect(ci_source.repo_slug).to eq(repo_slug)
        end
      end

      describe "#pull_request_id" do
        it "sets the pull_request_id" do
          expect(ci_source.pull_request_id).to eq(pr_num)
        end
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
  end
end
