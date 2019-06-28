require "danger/ci_source/circle"

RSpec.describe Danger::Jenkins do
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

  describe "errors" do
    it "raises an error when no env passed in" do
      expect { Danger::Jenkins.new(nil) }.to raise_error Danger::Jenkins::EnvNotFound
    end

    it "raises an error when empty env passed in" do
      expect { Danger::Jenkins.new({}) }.to raise_error Danger::Jenkins::EnvNotFound
    end
  end

  context "with GitHub" do
    before do
      valid_env["ghprbPullId"] = "1234"
      valid_env["GIT_URL"] = "https://github.com/danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `ghprbPullId` is missing" do
        valid_env["ghprbPullId"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `ghprbPullId` is empty" do
        valid_env["ghprbPullId"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesn't validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn't validate if `ghprbPullId` is missing" do
        valid_env["ghprbPullId"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if `ghprbPullId` is the empty string" do
        valid_env["ghprbPullId"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if `ghprbPullId` is not a number" do
        valid_env["ghprbPullId"] = "false"
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
      valid_env["gitlabMergeRequestIid"] = "1234"
      valid_env["gitlabMergeRequestId"] = "2345"
      valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.git"
    end

    describe ".validates_as_ci?" do
      it "validates when required env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestIid` is missing" do
        valid_env["gitlabMergeRequestIid"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestId` is missing" do
        valid_env["gitlabMergeRequestId"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestIid` is empty" do
        valid_env["gitlabMergeRequestIid"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `gitlabMergeRequestId` is empty" do
        valid_env["gitlabMergeRequestId"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesn't validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "validates if `gitlabMergeRequestIid` is missing and `gitlabMergeRequestId` is set" do
        valid_env["gitlabMergeRequestIid"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn't validate_as_pr if `gitlabMergeRequestIid` is the empty string" do
        valid_env["gitlabMergeRequestIid"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate if `gitlabMergeRequestIid` is missing and `gitlabMergeRequestId` is missing" do
        valid_env["gitlabMergeRequestIid"] = nil
        valid_env["gitlabMergeRequestId"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if `gitlabMergeRequestIid` is missing and `gitlabMergeRequestId` is the empty string" do
        valid_env["gitlabMergeRequestIid"] = nil
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

  context "with multibranch pipeline" do
    before do
      valid_env["GIT_URL"] = nil
      valid_env["CHANGE_ID"] = "647"
      valid_env["CHANGE_URL"] = "https://github.com/danger/danger/pull/647"
    end

    describe ".validates_as_ci?" do
      it "validates when requierd env variables are set" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `CHANGE_ID` is missing" do
        valid_env["CHANGE_ID"] = nil
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "validates even when `CHANGE_ID` is empty" do
        valid_env["CHANGE_ID"] = ""
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end

      it "doesn't validate when require env variables are not set" do
        expect(described_class.validates_as_ci?(invalid_env)).to be false
      end
    end

    describe ".validates_as_pr?" do
      it "validates when the required variables are set" do
        expect(described_class.validates_as_pr?(valid_env)).to be true
      end

      it "doesn't validate if `CHANGE_ID` is missing" do
        valid_env["CHANGE_ID"] = nil
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end

      it "doesn't validate_as_pr if `CHANGE_ID` is the empty string" do
        valid_env["CHANGE_ID"] = ""
        expect(described_class.validates_as_pr?(valid_env)).to be false
      end
    end

    describe ".repo_url()" do
      it "gets the GitHub url" do
        valid_env["CHANGE_URL"] = "https://github.com/danger/danger/pull/647"
        expect(described_class.repo_url(valid_env)).to eq("https://github.com/danger/danger")
      end

      it "gets the GitLab url" do
        valid_env["CHANGE_URL"] = "https://gitlab.com/danger/danger/merge_requests/1234"
        expect(described_class.repo_url(valid_env)).to eq("https://gitlab.com/danger/danger")
      end

      it "gets the BitBucket url" do
        valid_env["CHANGE_URL"] = "https://bitbucket.org/danger/danger/pull-requests/1"
        expect(described_class.repo_url(valid_env)).to eq("https://bitbucket.org/danger/danger")
      end

      it "gets the BitBucket Server url" do
        valid_env["CHANGE_URL"] = "https://bitbucket.example.com/projects/DANGER/repos/danger/pull-requests/1/overview"
        expect(described_class.repo_url(valid_env)).to eq("https://bitbucket.example.com/projects/DANGER/repos/danger")
      end
    end

    describe "#new" do
      it "sets the pull_request_id" do
        expect(source.pull_request_id).to eq("647")
      end
      it "sets the repo_url" do
        expect(source.repo_url).to eq("https://github.com/danger/danger")
      end
    end
  end

  context "Multiple remotes support" do
    it "gets out the repo slug from GIT_URL_1" do
      source = described_class.new(
        "JENKINS_URL" => "Hello",
        "GIT_URL_1" => "https://githug.com/danger/danger.git"
      )

      expect(source.repo_slug).to eq("danger/danger")
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug from a git+ssh repo" do
        expect(source.repo_slug).to eq("danger/danger")
      end

      it "gets out a repo slug from a https repo" do
        valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.git"

        expect(source.repo_slug).to eq("danger/danger")
      end

      it "get out a repo slug from a repo with dot in name" do
        valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.test.git"

        expect(source.repo_slug).to eq("danger/danger.test")
      end

      it "get out a repo slug from a repo with .git in name" do
        valid_env["GIT_URL"] = "https://gitlab.com/danger/danger.git.git"

        expect(source.repo_slug).to eq("danger/danger.git")
      end

      it "gets out a repo slug from a BitBucket Server" do
        valid_env["CHANGE_URL"] = "https://bitbucket.example.com/projects/DANGER/repos/danger/pull-requests/1/overview"

        expect(source.repo_slug).to eq("DANGER/danger")
      end

      it "gets out a repo slug with multiple groups ssh" do
        valid_env["GIT_URL"] = "git@gitlab.com:danger/systems/danger.git"

        expect(source.repo_slug).to eq("danger/systems/danger")
      end

      it "gets out a repo slug with multiple groups http" do
        valid_env["GIT_URL"] = "http://gitlab.com/danger/systems/danger.git"

        expect(source.repo_slug).to eq("danger/systems/danger")
      end

      it "gets out a repo slug with multiple groups https" do
        valid_env["GIT_URL"] = "https://gitlab.com/danger/systems/danger.git"

        expect(source.repo_slug).to eq("danger/systems/danger")
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

    it "supports BitBucket Cloud" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketCloud)
    end

    it "supports BitBucket Server" do
      expect(source.supported_request_sources).to include(Danger::RequestSources::BitbucketServer)
    end
  end
end
