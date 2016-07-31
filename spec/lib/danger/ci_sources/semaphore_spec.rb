require 'danger/ci_source/travis'

describe Danger::Semaphore do
  it 'validates when all semaphore variables are set' do
    env = { 'SEMAPHORE' => 'true',
            'PULL_REQUEST_NUMBER' => '800',
            'SEMAPHORE_REPO_SLUG' => 'artsy/eigen' }
    expect(Danger::Semaphore.validates_as_ci?(env)).to be true
  end

  it 'doesnt validate when not semaphore' do
    env = { 'CIRCLE' => 'true' }
    expect(Danger::Semaphore.validates_as_ci?(env)).to be false
  end

  it 'gets the pull request ID' do
    env = { 'PULL_REQUEST_NUMBER' => '2' }
    t = Danger::Semaphore.new(env)
    expect(t.pull_request_id).to eql('2')
  end

  it 'gets the repo address' do
    env = { 'SEMAPHORE_REPO_SLUG' => 'orta/danger' }
    t = Danger::Semaphore.new(env)
    expect(t.repo_slug).to eql('orta/danger')
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      'SEMAPHORE' => 'true',
      'PULL_REQUEST_NUMBER' => '800',
      'SEMAPHORE_REPO_SLUG' => 'artsy/eigen'
    }
    t = Danger::Semaphore.new(env)
    expect(t.repo_slug).to eql('artsy/eigen')
    expect(t.pull_request_id).to eql('800')
  end
end
