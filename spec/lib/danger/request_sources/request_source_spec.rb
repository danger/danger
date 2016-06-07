require 'danger/request_source/github'

describe Danger::RequestSources::RequestSource do
  describe "the base request source" do
    it 'validates when passed a corresponding repository' do
      git_mock = Danger::GitRepo.new
      allow(git_mock).to receive(:exec).with("remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-").and_return("git@github.com:artsy/eigen.git")

      g = stub_request_source
      g.scm = git_mock
      expect(g.validates?).to be true
    end

    it 'validates when passed a corresponding repository with custom host' do
      git_mock = Danger::GitRepo.new

      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }
      g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)
      g.scm = git_mock

      allow(git_mock).to receive(:exec).with("remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-").and_return("git@git.club-mateusa.com:artsy/eigen.git")
      expect(g.validates?).to be true
    end

    it 'doesn\'t validate when passed a wrong repository' do
      git_mock = Danger::GitRepo.new
      allow(git_mock).to receive(:exec).with("remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-").and_return("git@bitbucket.org:artsy/eigen.git")

      g = stub_request_source
      g.scm = git_mock
      expect(g.validates?).to be false
    end
  end
end
