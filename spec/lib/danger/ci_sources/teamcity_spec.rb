require 'danger/ci_source/teamcity'

describe Danger::CISource::TeamCity do
  it 'detects TeamCity' do
    env = { 'TEAMCITY_VERSION' => "42" }
    expect(Danger::CISource::TeamCity.validates?(env)).to be true
  end

  it 'gets out a repo slug' do
    env = { 'GITHUB_REPO_SLUG' => 'foo/bar' }
    subject = Danger::CISource::TeamCity.new(env)
    expect(subject.repo_slug).to eql('foo/bar')
  end

  it 'gets out a pull request id' do
    env = { 'GITHUB_PULL_REQUEST_ID' => '42' }
    subject = Danger::CISource::TeamCity.new(env)
    expect(subject.pull_request_id).to eql(42)
  end

  it 'gets out a repo url' do
    env = { 'GITHUB_REPO_URL' => 'http://example.org/' }
    subject = Danger::CISource::TeamCity.new(env)
    expect(subject.repo_url).to eql('http://example.org/')
  end
end
