require 'rest'
require 'spec_helper'
require 'danger/request_sources/github'
require 'danger/ci_source/circle'
require 'danger/ci_source/travis'

def stub_ci
  env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
  Danger::CISource::CircleCI.new(env)
end

def fixture(file)
  File.read("spec/fixtures/#{file}.json")
end

describe Danger::GitHub do
  it 'gets the right url from travis' do
    env = {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
      "TRAVIS_PULL_REQUEST" => "2",
      "TRAVIS_REPO_SLUG" => "orta/danger"
    }

    t = Danger::CISource::Travis.new(env)
    g = Danger::GitHub.new(t)
    expect(g.api_url).to eql("https://api.github.com/repos/orta/danger/pulls/2")
  end

  it "gets the right url from circle" do
    env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
    c = Danger::CISource::CircleCI.new(env)
    g = Danger::GitHub.new(c)
    expect(g.api_url).to eql("https://api.github.com/repos/artsy/eigen/pulls/800")
  end

  it 'gets the right url from buildkite' do
    env = { "BUILDKITE_PULL_REQUEST" => "12",
            "BUILDKITE_REPO" => "https://github.com/artsy/eigen" }
    c = Danger::CISource::Buildkite.new(env)
    g = Danger::GitHub.new(c)
    expect(g.api_url).to eql("https://api.github.com/repos/artsy/eigen/pulls/12")
  end

  it 'raises when GitHub fails' do
    @g = Danger::GitHub.new(stub_ci)
    response = double("response", ok?: false, status_code: 401, body: fixture("pr_response"))
    allow(REST).to receive(:get) { response }
    # dont log out in tests
    allow(@g).to receive(:puts).and_return("")

    expect do
      @g.fetch_details
    end.to raise_error("Could not get the pull request details from GitHub.")
  end

  describe "with working json" do
    before do
      @g = Danger::GitHub.new(stub_ci)
      response = double("response", ok?: true, body: fixture("pr_response"))
      allow(REST).to receive(:get) { response }
    end

    it 'sets its pr_json' do
      @g.fetch_details
      expect(@g.pr_json).to be_truthy
    end

    it 'sets the right commit sha' do
      @g.fetch_details

      expect(@g.pr_json['base']['sha']).to eql("704dc55988c6996f69b6873c2424be7d1de67bbe")
      expect(@g.pr_json['base']['sha']).to eql(@g.latest_pr_commit_ref)
    end
  end
end
