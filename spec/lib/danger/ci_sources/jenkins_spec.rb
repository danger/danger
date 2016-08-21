require "danger/ci_source/circle"

describe Danger::Jenkins do
  let(:valid_env) do
    {
      "JENKINS_URL" => "Hello",
      "GIT_URL" => "git@github.com:danger/danger.git"
    }
  end

  let(:invalid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

  context "with GitHub" do
    before do
      valid_env["ghprPullId"] = "1234"
      valid_env["GIT_URL"] = "https://github.com/danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `ghprPullId` is missing" do
        valid_env["ghprPullId"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `ghprPullId` is empty" do
        valid_env["ghprPullId"] = ""
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

      it "doesn not validate if `ghprPullId` is missing" do
        valid_env["ghprPullId"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if pull_request_repo is the empty string" do
        valid_env["ghprPullId"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    describe "#new" do
      it "sets the pull_request_id" do
        expect(source.pull_request_id).to eq("1234")
      end
    end
  end

  context "with GitLab" do
    before do
      valid_env["gitlabMergeRequestId"] = "1234"
      valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestId` is missing" do
        valid_env["gitlabMergeRequestId"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestId` is empty" do
        valid_env["gitlabMergeRequestId"] = ""
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

      it "doesn not validate if `gitlabMergeRequestId` is missing" do
        valid_env["gitlabMergeRequestId"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if pull_request_repo is the empty string" do
        valid_env["gitlabMergeRequestId"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      describe "#new" do
        it "sets the pull_request_id" do
          expect(source.pull_request_id).to eq("1234")
        end
      end
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug from a git+ssh repo" do
        expect(source.repo_slug).to eql("danger/danger")
      end

      it "gets out a repo slug from a https repo" do
        valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.git"
        expect(source.repo_slug).to eql("danger/danger")
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
