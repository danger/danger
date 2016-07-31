require 'danger/ci_source/teamcity'

describe Danger::TeamCity do
  it 'detects TeamCity' do
    env = { 'TEAMCITY_VERSION' => '42' }
    expect(Danger::TeamCity.validates_as_ci?(env)).to be true
  end

  it 'gets out a repo slug' do
    env = { 'GITHUB_REPO_SLUG' => 'foo/bar' }
    subject = Danger::TeamCity.new(env)
    expect(subject.repo_slug).to eql('foo/bar')
  end

  it 'gets out a pull request id' do
    env = { 'GITHUB_PULL_REQUEST_ID' => '42' }
    subject = Danger::TeamCity.new(env)
    expect(subject.pull_request_id).to eql(42)
  end

  it 'gets out a repo url' do
    env = { 'GITHUB_REPO_URL' => 'http://example.org/' }
    subject = Danger::TeamCity.new(env)
    expect(subject.repo_url).to eql('http://example.org/')
  end
end
