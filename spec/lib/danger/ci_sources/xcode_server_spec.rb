require 'danger/ci_source/xcode_server'

describe Danger::XcodeServer do
  it 'validates when Xcode Server has XCS_BOT_NAME env var' do
    env = {
      'XCS_BOT_NAME' => 'BuildaBot [danger/danger] PR #17'
    }
    expect(Danger::XcodeServer.validates_as_ci?(env)).to be true
  end

  it 'doesnt validate when Xcode Server does not have XCS_BOT_NAME env var' do
    env = { 'HAS_JOSH_K_SEAL_OF_APPROVAL' => 'true' }
    expect(Danger::XcodeServer.validates_as_ci?(env)).to be false
  end

  it 'gets out a repo slug and a pull request number from a bot name' do
    env = {
      'XCS_BOT_NAME' => 'BuildaBot [danger/danger] PR #17'
    }
    t = Danger::XcodeServer.new(env)
    expect(t.repo_slug).to eql('danger/danger')
    expect(t.pull_request_id).to eql('17')
  end
end
