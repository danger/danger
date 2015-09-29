require 'spec_helper'
require 'danger/request_sources/github'
require 'danger/ci_source/circle'
require 'danger/ci_source/travis'

describe Danger::GitHub do

  it 'gets the right url from travis' do
    env = {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
      "TRAVIS_PULL_REQUEST" => "2",
      "TRAVIS_REPO_SLUG" => "orta/danger"
    }

    t = Danger::Travis.new(env)
    g = Danger::GitHub.new(t)
    expect(g.api_url).to eql("https://api.github.com/repos/orta/danger/pulls/2")
  end

  it 'gets the right url from circle' do
    env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
    c = Danger::CircleCI.new(env)
    g = Danger::GitHub.new(c)
    expect(g.api_url).to eql("https://api.github.com/repos/artsy/eigen/pulls/800")
  end

end
