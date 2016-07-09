require "danger/ci_source/travis"

describe Danger::CISource::Travis do
  it "validates when all Travis environment vars are set and Josh K says so" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_PULL_REQUEST" => "800",
            "TRAVIS_REPO_SLUG" => "artsy/eigen" }
    expect(Danger::CISource::Travis.validates?(env)).to be true
  end

  it "doesnt validate when Josh K aint around" do
    env = { "CIRCLE" => "true" }
    expect(Danger::CISource::Travis.validates?(env)).to be false
  end

  it "gets the pull request ID" do
    env = { "TRAVIS_PULL_REQUEST" => "2" }
    t = Danger::CISource::Travis.new(env)
    expect(t.pull_request_id).to eql("2")
  end

  it "gets the repo address" do
    env = { "TRAVIS_REPO_SLUG" => "orta/danger" }
    t = Danger::CISource::Travis.new(env)
    expect(t.repo_slug).to eql("orta/danger")
  end

  it "gets out a repo slug and pull request number" do
    env = {
      "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
      "TRAVIS_PULL_REQUEST" => "800",
      "TRAVIS_REPO_SLUG" => "artsy/eigen",
      "TRAVIS_COMMIT_RANGE" => "759adcbd0d8f...13c4dc8bb61d"
    }
    t = Danger::CISource::Travis.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end
end
