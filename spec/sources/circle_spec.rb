require 'spec_helper'
require 'danger/ci_source/circle'

describe Danger::CircleCI do
  it 'validates when circle env var is found' do
    env = { "CIRCLE_BUILD_NUM" => "true" }
    expect(Danger::CircleCI.validates?(env)).to be true
  end

  it 'doesnt validate when circle ci is not found' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CircleCI.validates?(env)).to be false
  end

  it 'gets out a repo slug and pull request number' do
    env = { "CIRCLE_BUILD_NUM" => "true", "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
    t = Danger::CircleCI.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end
end
