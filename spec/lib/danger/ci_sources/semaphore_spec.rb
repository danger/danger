require 'danger/ci_source/travis'

describe Danger::CISource::Semaphore do
  it 'validates when semaphore' do
    env = { "SEMAPHORE" => "true" }
    expect(Danger::CISource::Semaphore.validates?(env)).to be true
  end

  it 'doesnt validate when not semaphore' do
    env = { "CIRCLE" => "true" }
    expect(Danger::CISource::Semaphore.validates?(env)).to be false
  end

  it 'gets the pull request ID' do
    env = { "PULL_REQUEST_NUMBER" => "2" }
    t = Danger::CISource::Semaphore.new(env)
    expect(t.pull_request_id).to eql("2")
  end

  it 'gets the repo address' do
    env = { "SEMAPHORE_REPO_SLUG" => "orta/danger" }
    t = Danger::CISource::Semaphore.new(env)
    expect(t.repo_slug).to eql("orta/danger")
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      "SEMAPHORE" => "true",
      "PULL_REQUEST_NUMBER" => "800",
      "SEMAPHORE_REPO_SLUG" => "artsy/eigen"
    }
    t = Danger::CISource::Semaphore.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end
end
