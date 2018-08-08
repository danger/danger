require "danger/ci_source/circle"

RSpec.describe Danger::CircleCI do
  let(:legit_pr) { "https://github.com/artsy/eigen/pulls/800" }
  let(:not_legit_pr) { "https://github.com/orta" }

  let(:valid_env) do
    {
      "CIRCLE_BUILD_NUM" => "1500",
      "CI_PULL_REQUEST" => legit_pr,
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen",
      "CIRCLE_REPOSITORY_URL" => "git@github.com:artsy/eigen.git"
    }
  end

  let(:invalid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when all required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates when the `CI_PULL_REQUEST` is missing" do
      valid_env["CI_PULL_REQUEST"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates when the `CI_PULL_REQUEST` is not legit" do
      valid_env["CI_PULL_REQUEST"] = not_legit_pr
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when all required env variables are not set" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe ".validates_as_pr?" do
    it "validates when required env variables are set" do
      expect(described_class.validates_as_pr?(valid_env)).to be true
    end

    context "with missing `CI_PULL_REQUEST` and `CIRCLE_PULL_REQUEST`" do
      context "and with `CIRCLE_PR_NUMBER`" do
        before do
          valid_env["CI_PULL_REQUEST"] = nil
          valid_env["DANGER_CIRCLE_CI_API_TOKEN"] = "testtoken"
          valid_env["CIRCLE_PR_NUMBER"] = "800"
        end

        it "validates when required env variables are set" do
          expect(described_class.validates_as_pr?(valid_env)).to be true
        end
      end
      context "and with missing `CIRCLE_PR_NUMBER`" do
        before do
          valid_env["CI_PULL_REQUEST"] = nil
          valid_env["DANGER_CIRCLE_CI_API_TOKEN"] = "testtoken"
          build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
          allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", "testtoken").and_return(build_response)
        end

        it "validates when required env variables are set" do
          expect(described_class.validates_as_pr?(valid_env)).to be true
        end
      end
    end

    context "uses `CIRCLE_PULL_REQUEST` if available" do
      before do
        valid_env["CI_PULL_REQUEST"] = nil
        valid_env["CIRCLE_PULL_REQUEST"] = "https://github.com/artsy/eigen/pulls/800"
      end

      it "validates when required env variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end
    end

    it "does not validate if `CI_PULL_REQUEST` is empty" do
      valid_env["CI_PULL_REQUEST"] = ""
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end

    it "doest not validate when required env variables are not set" do
      expect(described_class.validates_as_pr?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "does not get a PR id when it has a bad PR url" do
      valid_env["CI_PULL_REQUEST"] = not_legit_pr
      expect { source }.to raise_error RuntimeError
    end

    it "sets the repo_slug" do
      expect(source.repo_slug).to eq("artsy/eigen")
    end

    it "sets the pull_request_id" do
      expect(source.pull_request_id).to eq("800")
    end

    it "sets the repo_url" do
      expect(source.repo_url).to eq("git@github.com:artsy/eigen.git")
    end

    context "with missing `CI_PULL_REQUEST`" do
      before do
        build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
        allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", nil).and_return(build_response)
      end

      it "sets the repo_slug" do
        expect(source.repo_slug).to eq("artsy/eigen")
      end

      it "sets the pull_request_id" do
        expect(source.pull_request_id).to eq("800")
      end
    end
  end

  describe "#supported_request_sources" do
    it "supports GitHub" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::GitHub)
    end

    it "supports BitBucket Cloud" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketCloud)
    end
  end
end
