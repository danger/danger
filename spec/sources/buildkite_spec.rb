require 'spec_helper'
require 'danger/ci_source/circle'

describe Danger::CISource::Buildkite do
  it "validates when buildkite env var is found" do
    env = { "BUILDKITE" => "true" }
    expect(Danger::CISource::Buildkite.validates?(env)).to be true
  end

  it "doesnt validate when buildkite is not found" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CISource::Buildkite.validates?(env)).to be false
  end

  it "gets out a repo slug from a git+ssh repo and pull request number" do
    env = { "BUILDKITE_REPO" => "git@github.com:KrauseFx/danger.git",
            "BUILDKITE_PULL_REQUEST" => "12" }
    t = Danger::CISource::Buildkite.new(env)
    expect(t.repo_slug).to eql("KrauseFx/danger")
    expect(t.pull_request_id).to eql("12")
  end

  it "gets out a repo slug from a https repo and pull request number" do
    env = {
      "BUILDKITE_REPO" => "https://github.com/KrauseFx/danger.git",
      "BUILDKITE_PULL_REQUEST" => "14",
      "BUILDKITE_BRANCH" => "my_branch"
    }
    t = Danger::CISource::Buildkite.new(env)
    expect(t.repo_slug).to eql("KrauseFx/danger")
    expect(t.pull_request_id).to eql("14")
    expect(t.base_commit).to eql("master")
    expect(t.head_commit).to eql("my_branch")
  end
end
