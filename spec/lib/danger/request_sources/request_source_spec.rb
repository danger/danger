require "danger/request_sources/github/github"

RSpec.describe Danger::RequestSources::RequestSource, host: :github do
  describe "the base request source" do
    it "validates when passed a corresponding repository" do
      git_mock = Danger::GitRepo.new
      allow(git_mock).to receive(:exec).with("remote show origin -n").and_return("Fetch URL: git@github.com:artsy/eigen.git")

      g = stub_request_source
      g.scm = git_mock
      expect(g.validates_as_ci?).to be true
    end

    it "validates when passed a corresponding repository with custom host" do
      git_mock = Danger::GitRepo.new

      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }
      g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)
      g.scm = git_mock

      allow(git_mock).to receive(:exec).with("remote show origin -n").and_return("Fetch URL: git@git.club-mateusa.com:artsy/eigen.git")
      expect(g.validates_as_ci?).to be true
    end
  end

  describe ".source_name" do
    context "GitHub" do
      it "returns the name of request source" do
        result = Danger::RequestSources::GitHub.source_name

        expect(result).to eq "GitHub"
      end
    end

    context "GitLab" do
      it "returns the name of request source" do
        result = Danger::RequestSources::GitLab.source_name

        expect(result).to eq "GitLab"
      end
    end

    context "BitbucketCloud" do
      it "returns the name of request source" do
        result = Danger::RequestSources::BitbucketCloud.source_name

        expect(result).to eq "BitbucketCloud"
      end
    end

    context "BitbucketCloud" do
      it "returns the name of request source" do
        result = Danger::RequestSources::BitbucketServer.source_name

        expect(result).to eq "BitbucketServer"
      end
    end
  end

  describe ".available_source_names_and_envs" do
    it "returns list of items contains source name and envs" do
      result = described_class.available_source_names_and_envs.join(", ")

      expect(result).to include("- GitHub:")
      expect(result).to include("- GitLab:")
      expect(result).to include("- BitbucketCloud:")
      expect(result).to include("- BitbucketServer:")
    end
  end
end
