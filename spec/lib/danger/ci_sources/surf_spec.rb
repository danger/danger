require "danger/ci_source/surf"

describe Danger::CISource::Surf do
  it "validates when all Surf environment vars are set" do
    env = { "SURF_REPO" => "https://github.com/surf-build/surf",
            "SURF_NWO" => "surf-build/surf" }

    expect(Danger::CISource::Surf.validates?(env)).to be true
  end

  it "doesnt validate when Surf aint around" do
    env = { "CIRCLE" => "true" }
    expect(Danger::CISource::Surf.validates?(env)).to be false
  end

  it "gets the pull request ID" do
    env = { "SURF_PR_NUM" => "2" }
    t = Danger::CISource::Surf.new(env)
    expect(t.pull_request_id).to eql("2")
  end

  it "gets the repo address" do
    env = { "SURF_NWO" => "orta/danger" }
    t = Danger::CISource::Surf.new(env)
    expect(t.repo_slug).to eql("orta/danger")
  end

  it "gets out a repo slug and pull request number" do
    env = {
      "SURF_PR_NUM" => "800",
      "SURF_NWO" => "artsy/eigen",
      "SURF_REPO" => "https://github.com/artsy/eigen"
    }
    t = Danger::CISource::Surf.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end
end
