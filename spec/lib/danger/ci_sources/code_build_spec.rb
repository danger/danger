require "danger/ci_source/github_actions"

RSpec.describe Danger::CodeBuild do
  # CODEBUILD_SOURCE_VERSION=pr/2512 CODEBUILD_SOURCE_REPO_URL=https://github.o-in.dwango.co.jp/zane/zane-Soroban-web CODEBUILD_BUILD_ID=zane-soroban:cf613895-4a78-4456-8568-a53784fa75c5
  let(:valid_env) do
    {
      "CODEBUILD_BUILD_ID" => "codebuild:cf613895-4a78-4456-8568-a53784fa75c5",
      "CODEBUILD_SOURCE_VERSION" => "pr/1234",
      "CODEBUILD_SOURCE_REPO_URL" => source_repo_url
    }
  end

  let(:source_repo_url) { "https://github.com/danger/danger.git" }

  let(:env) { valid_env }
  let(:source) { described_class.new(env) }

  context "with GitHub" do
    describe ".validates_as_ci?" do
      subject { described_class.validates_as_ci?(env) }
      context "when required env variables are set" do
        let(:env) { valid_env }

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
      let(:env) { valid_env }

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
      it "get out a pull request id" do
        expect(source.pull_request_id).to eq 1234
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
