require "danger/ci_source/circle_api"

RSpec.describe Danger::CircleAPI do
  it "gets out a repo slug, pull request number and commit refs when PR url is not found" do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }

    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", nil).and_return(build_response)

    result = Danger::CircleCI.new(env)

    expect(result).to have_attributes(
      repo_slug: "artsy/eigen",
      pull_request_id: "2606"
    )
  end

  it "uses the new token DANGER_CIRCLE_CI_API_TOKEN if available" do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "DANGER_CIRCLE_CI_API_TOKEN" => "token2",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen"
    }
    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", "token2").and_return(build_response)

    result = Danger::CircleAPI.new.pull_request_url(env)

    expect(result).to eq("https://github.com/artsy/eigen/pull/2606")
  end

  it "uses Circle CI API to grab the url if available" do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "DANGER_CIRCLE_CI_API_TOKEN" => "token",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen"
    }
    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", "token").and_return(build_response)

    result = Danger::CircleAPI.new.pull_request_url(env)

    expect(result).to eq("https://github.com/artsy/eigen/pull/2606")
  end

  it "uses Circle CI API to and can tell you it's not a PR'" do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "DANGER_CIRCLE_CI_API_TOKEN" => "token",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen"
    }
    build_response = JSON.parse(fixture("circle_build_no_pr_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", "token").and_return(build_response)

    result = Danger::CircleAPI.new.pull_request?(env)

    expect(result).to be_falsy
  end
end
