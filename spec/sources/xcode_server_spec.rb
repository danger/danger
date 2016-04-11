require 'danger/ci_source/xcode_server'

describe Danger::CISource::XcodeServer do
  it "validates when Xcode Server has XCS_BOT_NAME env var" do
    env = {
      "XCS_BOT_NAME" => "BuildaBot [danger/danger] PR #17"
    }
    expect(Danger::CISource::XcodeServer.validates?(env)).to be true
  end

  it "doesnt validate when Xcode Server does not have XCS_BOT_NAME env var" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    expect(Danger::CISource::XcodeServer.validates?(env)).to be false
  end

  it "gets out a repo slug and a pull request number from a bot name" do
    env = {
      "XCS_BOT_NAME" => "BuildaBot [danger/danger] PR #17"
    }
    t = Danger::CISource::XcodeServer.new(env)
    expect(t.repo_slug).to eql("danger/danger")
    expect(t.pull_request_id).to eql("17")
  end
end
