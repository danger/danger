require 'spec_helper'
require 'danger/ci_source/circle'

describe Danger::CISource::CircleCI do
  legit_pr = "https://github.com/orta/thing/pulls/45"
  not_legit_pr = "https://github.com/orta"

  it 'validates when circle env var is found and it has a real PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true", "CI_PULL_REQUEST" => legit_pr }
    expect(Danger::CISource::CircleCI.validates?(env)).to be true
  end

  it 'validates when circle env var is found and it has a bad PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true", "CI_PULL_REQUEST" => not_legit_pr }
    expect(Danger::CISource::CircleCI.validates?(env)).to be true
  end

  it 'doesnt get a PR id when it has a bad PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true", "CI_PULL_REQUEST" => not_legit_pr }
    t = Danger::CISource::CircleCI.new(env)
    expect(t.pull_request_id).to be nil
  end

  it 'doesnt validate when circle ci is not found' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CISource::CircleCI.validates?(env)).to be false
  end

  it 'gets out a repo slug, pull request number and commit refs' do
    env = {
      "CIRCLE_BUILD_NUM" => "true",
      "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }
    t = Danger::CISource::CircleCI.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
    expect(t.base_commit).to eql("759adcbd0d8f")
    expect(t.head_commit).to eql("13c4dc8bb61d")
  end

  it 'handles funky compare URLs' do
    env = {
      "CIRCLE_BUILD_NUM" => "true",
      "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f^...13c4dc8bb61d"
    }
    t = Danger::CISource::CircleCI.new(env)
    expect(t.base_commit).to eql("759adcbd0d8f^")
    expect(t.head_commit).to eql("13c4dc8bb61d")
  end
end
