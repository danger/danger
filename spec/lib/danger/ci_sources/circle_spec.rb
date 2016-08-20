require "danger/ci_source/circle"

describe Danger::CircleCI do
  legit_pr = "https://github.com/orta/thing/pulls/45"
  not_legit_pr = "https://github.com/orta"

  it "validates when circle all env vars are set" do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CircleCI.validates_as_ci?(env)).to be true
  end

  it "validates when circle env var is found and it has a bad PR url" do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => not_legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CircleCI.validates_as_ci?(env)).to be true
  end

  it "doesnt get a PR id when it has a bad PR url" do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => not_legit_pr,
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect { Danger::CircleCI.new(env) }.to raise_error RuntimeError
  end

  it "does validate when circle env var is found and it has no PR url" do
    env = { "CIRCLE_BUILD_NUM" => "true",
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    expect(Danger::CircleCI.validates_as_ci?(env)).to be true
  end

  it "doesn't validate_as_pr if ci_pull_request is empty" do
    env = { "CI_PULL_REQUEST" => "" }
    expect(Danger::CircleCI.validates_as_pr?(env)).to be false
  end

  it "doesnt validate when circle ci is not found" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CircleCI.validates_as_ci?(env)).to be false
  end

  it "gets out a repo slug and pull request number" do
    env = {
      "CIRCLE_BUILD_NUM" => "true",
      "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }
    t = Danger::CircleCI.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end

  it "gets out a repo slug, pull request number and commit refs when PR url is not found" do
    env = {
      "CIRCLE_BUILD_NUM" => "1500",
      "CIRCLE_PROJECT_USERNAME" => "artsy",
      "CIRCLE_PROJECT_REPONAME" => "eigen",
      "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
    }

    build_response = JSON.parse(fixture("circle_build_response"), symbolize_names: true)
    allow_any_instance_of(Danger::CircleAPI).to receive(:fetch_build).with("artsy/eigen", "1500", nil).and_return(build_response)

    t = Danger::CircleCI.new(env)

    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("1130")
  end
end
