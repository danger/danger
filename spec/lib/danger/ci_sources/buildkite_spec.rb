# frozen_string_literal: true

require "danger/ci_source/buildkite"

RSpec.describe Danger::Buildkite do
  let(:valid_env) do
    {
      "BUILDKITE" => "true",
      "BUILDKITE_REPO" => "git@github.com:Danger/danger.git",
      "BUILDKITE_PULL_REQUEST_REPO" => "git@github.com:KrauseFx/danger.git",
      "BUILDKITE_PULL_REQUEST" => "12"
    }
  end
  let(:invalid_env) do
    {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true"
    }
  end
  let(:source) { described_class.new(valid_env) }

  describe ".validates_as_ci?" do
    it "validates when required env variables are set" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates even when `BUILDKITE_PULL_REQUEST_REPO` is missing" do
      valid_env["BUILDKITE_PULL_REQUEST_REPO"] = nil
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "validates even when `BUILDKITE_PULL_REQUEST_REPO` is empty" do
      valid_env["BUILDKITE_PULL_REQUEST_REPO"] = ""
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

    it "doesn not validate if `BUILDKITE_PULL_REQUEST_REPO` is missing" do
      valid_env["BUILDKITE_PULL_REQUEST_REPO"] = nil
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end

    it "doesn't validate_as_pr if pull_request_repo is the empty string" do
      valid_env["BUILDKITE_PULL_REQUEST_REPO"] = ""
      expect(described_class.validates_as_pr?(valid_env)).to be false
    end
  end

  describe "#new" do
    describe "repo slug" do
      it "gets out a repo slug from a git+ssh repo" do
        expect(source.repo_slug).to eq("Danger/danger")
      end

      it "gets out a repo slug from a https repo" do
        valid_env["BUILDKITE_REPO"] = "https://github.com/Danger/danger.git"
        expect(source.repo_slug).to eq("Danger/danger")
      end

      it "gets out a repo slug from a repo with dots in it" do
        valid_env["BUILDKITE_REPO"] = "https://github.com/Danger/danger.systems.git"
        expect(source.repo_slug).to eq("Danger/danger.systems")
      end
    end

    it "sets the pull request id" do
      expect(source.pull_request_id).to eq("12")
    end

    describe "commit sha" do
      let(:head_sha) { "34c5c7793cb3b279e22454cb6750c80560547b3a" }
      let(:merge_sha) { "414cb0069601a32b00bd122a2380cd283626a8e5" }

      it "uses the built commit" do
        valid_env["BUILDKITE_COMMIT"] = head_sha
        expect(source.commit_sha).to eq(head_sha)
      end

      it "prefers the pull request head commit over the merge commit" do
        valid_env["BUILDKITE_COMMIT"] = merge_sha
        valid_env["BUILDKITE_PULL_REQUEST_HEAD_COMMIT"] = head_sha
        expect(source.commit_sha).to eq(head_sha)
      end

      it "is nil when the commit is not resolved" do
        valid_env["BUILDKITE_COMMIT"] = "HEAD"
        expect(source.commit_sha).to be_nil
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
