require 'danger/ci_source/circle'

describe Danger::CISource::Jenkins do
  it 'validates when jenkins env var is found' do
    env = {
      'GIT_URL' => 'https://github.com/danger/danger.git',
      'ghprbPullId' => '1234'
    }
    expect(Danger::CISource::Jenkins.validates?(env)).to be true
  end

  it 'doesnt validate when jenkins is not found' do
    env = { 'HAS_JOSH_K_SEAL_OF_APPROVAL' => 'true' }
    expect(Danger::CISource::Jenkins.validates?(env)).to be false
  end

  it 'gets out a repo slug from a git+ssh repo and pull request number' do
    env = {
      'GIT_URL' => 'git@github.com:danger/danger.git',
      'ghprbPullId' => '12'
    }
    t = Danger::CISource::Jenkins.new(env)
    expect(t.repo_slug).to eql('danger/danger')
    expect(t.pull_request_id).to eql('12')
  end

  it 'gets out a repo slug from a https repo and pull request number' do
    env = {
      'GIT_URL' => 'https://github.com/danger/danger.git',
      'ghprbPullId' => '14'
    }
    t = Danger::CISource::Jenkins.new(env)
    expect(t.repo_slug).to eql('danger/danger')
    expect(t.pull_request_id).to eql('14')
  end
end
