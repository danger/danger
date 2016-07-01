require 'danger/ci_source/circle'

describe Danger::CISource::CircleCI do
  legit_pr = "https://github.com/orta/thing/pulls/45"
  not_legit_pr = "https://github.com/orta"

  it 'validates when circle all env vars are set' do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CISource::CircleCI.validates?(env)).to be true
  end

  it 'validates when circle env var is found and it has a bad PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => not_legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CISource::CircleCI.validates?(env)).to be true
  end

  it 'doesnt get a PR id when it has a bad PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => not_legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    t = Danger::CISource::CircleCI.new(env)
    expect(t.pull_request_id).to be nil
  end

  it 'does validate when circle env var is found and it has no PR url' do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CISource::CircleCI.validates?(env)).to be true
  end

  it 'doesnt validate when circle ci is not found' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CISource::CircleCI.validates?(env)).to be false
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      "CIRCLE_BUILD_NUM" => "true",
      "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }
    t = Danger::CISource::CircleCI.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end

  it 'gets out a repo slug, pull request number and commit refs when PR url is not found' do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }
    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500").and_return(build_response)

    t = Danger::CISource::CircleCI.new(env)

    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("1130")
  end

  it 'uses Circle CI API token if available' do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "CIRCLE_CI_API_TOKEN" => "token",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen"
    }
    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500").and_return(build_response)

    t = Danger::CISource::CircleCI.new(env)
    expect(t.client.circle_token).to eql("token")
  end
end
