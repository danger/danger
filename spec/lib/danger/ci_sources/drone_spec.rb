require 'danger/ci_source/drone'

describe Danger::CISource::Drone do
  it 'validates when DRONE variable is set' do
    env = { "DRONE" => "true" }
    expect(Danger::CISource::Drone.validates?(env)).to be true
  end

  it 'does not validate when DRONE is not set' do
    env = { "CIRCLE" => "true" }
    expect(Danger::CISource::Drone.validates?(env)).to be false
  end

  it 'gets the pull request ID' do
    env = { "DRONE_PULL_REQUEST" => "2" }
    t = Danger::CISource::Drone.new(env)
    expect(t.pull_request_id).to eql("2")
  end

  it 'gets the repo address' do
    env = { "DRONE_REPO" => "orta/danger" }
    t = Danger::CISource::Drone.new(env)
    expect(t.repo_slug).to eql("orta/danger")
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      "DRONE" => "true",
      "DRONE_PULL_REQUEST" => "800",
      "DRONE_REPO" => "artsy/eigen"
    }
    t = Danger::CISource::Drone.new(env)
    expect(t.repo_slug).to eql("artsy/eigen")
    expect(t.pull_request_id).to eql("800")
  end
end
