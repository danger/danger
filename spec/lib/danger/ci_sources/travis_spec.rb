require 'danger/ci_source/travis'

describe Danger::Travis do
  it 'validates when all Travis environment vars are set and Josh K says so' do
    env = { 'HAS_JOSH_K_SEAL_OF_APPROVAL' => 'true',
            'TRAVIS_PULL_REQUEST' => '800',
            'TRAVIS_REPO_SLUG' => 'artsy/eigen' }
    expect(Danger::Travis.validates_as_ci?(env)).to be true
    expect(Danger::Travis.validates_as_pr?(env)).to be true
  end

  it 'validates as Travis but not as a PR' do
    env = { 'HAS_JOSH_K_SEAL_OF_APPROVAL' => 'true' }
    expect(Danger::Travis.validates_as_ci?(env)).to be true
    expect(Danger::Travis.validates_as_pr?(env)).to be false
  end

  it 'doesnt validate when Josh K aint around' do
    env = { 'CIRCLE' => 'true' }
    expect(Danger::Travis.validates_as_ci?(env)).to be false
  end

  it 'fails the PR check when the pull request is false ' do
    env = { 'TRAVIS_PULL_REQUEST' => 'false' }
    expect(Danger::Travis.validates_as_pr?(env)).to be_falsey
  end

  it 'gets the pull request ID' do
    env = { 'TRAVIS_PULL_REQUEST' => '2' }
    t = Danger::Travis.new(env)
    expect(t.pull_request_id).to eql('2')
  end

  it 'gets the repo address' do
    env = { 'TRAVIS_REPO_SLUG' => 'orta/danger' }
    t = Danger::Travis.new(env)
    expect(t.repo_slug).to eql('orta/danger')
  end

  it 'gets out a repo slug and pull request number' do
    env = {
      'HAS_JOSH_K_SEAL_OF_APPROVAL' => 'true',
      'TRAVIS_PULL_REQUEST' => '800',
      'TRAVIS_REPO_SLUG' => 'artsy/eigen',
      'TRAVIS_COMMIT_RANGE' => '759adcbd0d8f...13c4dc8bb61d'
    }
    t = Danger::Travis.new(env)
    expect(t.repo_slug).to eql('artsy/eigen')
    expect(t.pull_request_id).to eql('800')
  end
end
