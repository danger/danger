require "danger/ci_source/github_actions"

RSpec.describe Danger::CodeBuild do
  let(:valid_env) do
    {
      "CODEBUILD_BUILD_ID" => "codebuild:cf613895-4a78-4456-8568-a53784fa75c5",
      "CODEBUILD_SOURCE_VERSION" => "pr/1234",
      "CODEBUILD_WEBHOOK_TRIGGER" => "pr/1234",
      "CODEBUILD_SOURCE_REPO_URL" => source_repo_url
    }
  end
  let(:env) { valid_env }
  let(:source_repo_url) { "https://github.com/danger/danger.git" }
  let(:source) { described_class.new(env) }

  context "with GitHub" do
    describe ".validates_as_ci?" do
      subject { described_class.validates_as_ci?(env) }
      context "when required env variables are set" do
        it "validates" do
          is_expected.to be true
        end
      end

      context "when required env variables are not set" do
        let(:env) { {} }

        it "doesn't validates" do
          is_expected.to be false
        end
      end
    end

    describe ".validates_as_pr?" do
      subject { described_class.validates_as_pr?(env) }

      context "when not batch build" do
        context "when `CODEBUILD_SOURCE_VERSION` like a 'pr/1234" do
          let(:env) { valid_env.merge({ "CODEBUILD_SOURCE_VERSION" => "pr/1234" }) }

          it "validates" do
            is_expected.to be true
          end
        end

        context "when `CODEBUILD_SOURCE_VERSION` is commit hash" do
          let(:env) { valid_env.merge({ "CODEBUILD_SOURCE_VERSION" => "6548dbc49fe57e1fe7507a7a4b815639a62e9f90" }) }

          it "doesn't validates" do
            is_expected.to be false
          end
        end

        context "when `CODEBUILD_SOURCE_VERSION` is missing" do
          let(:env) { valid_env.tap { |e| e.delete("CODEBUILD_SOURCE_VERSION") } }

          it "doesn't validates" do
            is_expected.to be false
          end
        end
      end

      context "when batch build" do
        before do
          valid_env["CODEBUILD_SOURCE_VERSION"] = "6548dbc49fe57e1fe7507a7a4b815639a62e9f90"
          valid_env["CODEBUILD_BATCH_BUILD_IDENTIFIER"] = "build1"
        end

        context "when `CODEBUILD_WEBHOOK_TRIGGER` like a 'pr/1234" do
          let(:env) { valid_env.merge({ "CODEBUILD_WEBHOOK_TRIGGER" => "pr/1234" }) }

          it "validates" do
            is_expected.to be true
          end
        end

        context "when `CODEBUILD_WEBHOOK_TRIGGER` like a 'branch/branch_name'" do
          let(:env) { valid_env.merge({ "CODEBUILD_WEBHOOK_TRIGGER" => "branch/branch_name" }) }

          it "doesn't validates" do
            is_expected.to be false
          end
        end

        context "when `CODEBUILD_WEBHOOK_TRIGGER` like a 'tag/v1.0.0'" do
          let(:env) { valid_env.merge({ "CODEBUILD_WEBHOOK_TRIGGER" => "tag/v1.0.0" }) }

          it "doesn't validates" do
            is_expected.to be false
          end
        end

        context "when `CODEBUILD_WEBHOOK_TRIGGER` is missing" do
          let(:env) { valid_env.tap { |e| e.delete("CODEBUILD_WEBHOOK_TRIGGER") } }

          it "doesn't validates" do
            is_expected.to be false
          end
        end
      end
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug" do
        expect(source.repo_slug).to eq("danger/danger")
      end

      context "when `CODEBUILD_SOURCE_REPO_URL` is not ended with '.git'" do
        let(:source_repo_url) { "https://github.com/danger/danger" }

        it "also gets out a repo slug" do
          expect(source.repo_slug).to eq("danger/danger")
        end
      end

      context "when `CODEBUILD_SOURCE_REPO_URL` is hosted on github enterprise" do
        let(:env) { valid_env.merge({ "DANGER_GITHUB_HOST" => "github.example.com" }) }
        let(:source_repo_url) { "https://github.example.com/danger/danger" }

        it "also gets out a repo slug" do
          expect(source.repo_slug).to eq("danger/danger")
        end
      end
    end

    describe "pull request id" do
      context "when not batch build" do
        it "get out a pull request id" do
          expect(source.pull_request_id).to eq 1234
        end
      end

      context "when batch build" do
        before do
          valid_env["CODEBUILD_SOURCE_VERSION"] = "6548dbc49fe57e1fe7507a7a4b815639a62e9f90"
          valid_env["CODEBUILD_BATCH_BUILD_IDENTIFIER"] = "build1"
        end

        it "get out a pull request id" do
          expect(source.pull_request_id).to eq 1234
        end
      end
    end

    describe "repo url" do
      it "get out a repo url" do
        expect(source.repo_url).to eq "https://github.com/danger/danger"
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end
  end
end
