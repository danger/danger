require "danger/danger_core/environment_manager"

describe Danger::EnvironmentManager do
  it "does not return a CI source with no ENV deets" do
    env = { "KEY" => "VALUE" }
    expect(Danger::EnvironmentManager.local_ci_source(env)).to eq nil
  end

  it "stores travis in the source" do
    number = 123
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane",
            "TRAVIS_PULL_REQUEST" => number.to_s }
    e = Danger::EnvironmentManager.new(env)
    expect(e.ci_source.pull_request_id).to eq(number.to_s)
  end

  it "stores circle in the source" do
    number = 800
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/#{number}",
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.ci_source.pull_request_id).to eq(number.to_s)
  end

  it "creates a GitHub attr" do
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane",
            "TRAVIS_PULL_REQUEST" => 123.to_s }
    e = Danger::EnvironmentManager.new(env)
    expect(e.request_source).to be_truthy
  end

  it "skips push runs and only runs for pull requests" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::EnvironmentManager.local_ci_source(env)).to be_truthy
    expect(Danger::EnvironmentManager.pr?(env)).to eq(false)
  end
end
