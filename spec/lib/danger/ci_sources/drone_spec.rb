require 'danger/ci_source/drone'

describe Danger::Drone do
  it 'validates when DRONE variable is set' do
    env = { 'DRONE' => 'true',
            'DRONE_REPO' => 'danger/danger',
            'DRONE_PULL_REQUEST' => 1 }
    expect(Danger::Drone.validates_as_ci?(env)).to be true
  end

  it 'does not validate when DRONE is not set' do
    env = { 'CIRCLE' => 'true' }
    expect(Danger::Drone.validates_as_ci?(env)).to be false
  end

  it 'does not validate PR when DRONE_PULL_REQUEST is set to non int value' do
    env = { 'CIRCLE' => 'true',
            'DRONE_REPO' => 'danger/danger',
            'DRONE_PULL_REQUEST' => 'maku' }
    expect(Danger::Drone.validates_as_pr?(env)).to be false
  end

  it 'does not validate  PRwhen DRONE_PULL_REQUEST is set to non positive int value' do
    env = { 'CIRCLE' => 'true',
            'DRONE_REPO' => 'danger/danger',
            'DRONE_PULL_REQUEST' => -1 }
    expect(Danger::Drone.validates_as_pr?(env)).to be false
  end

  it 'gets the pull request ID' do
    env = { 'DRONE_PULL_REQUEST' => '2' }
    t = Danger::Drone.new(env)
    expect(t.pull_request_id).to eql('2')
  end

  it 'gets the repo address' do
    env = { 'DRONE_REPO' => 'orta/danger' }
    t = Danger::Drone.new(env)
    expect(t.repo_slug).to eql('orta/danger')
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      'DRONE' => 'true',
      'DRONE_PULL_REQUEST' => '800',
      'DRONE_REPO' => 'artsy/eigen'
    }
    t = Danger::Drone.new(env)
    expect(t.repo_slug).to eql('artsy/eigen')
    expect(t.pull_request_id).to eql('800')
  end
end
