require 'danger/ci_source/circle_api'

describe Danger::CircleAPI do
  api_path = 'project/artsy/eigen/1500'
  accept_json = { accept: 'application/json' }

  before do
    build_response = fixture('circle_build_response')
    @mocked_response = Faraday::Response.new(body: build_response, status: 200)
    @expected_json_response = JSON.parse(build_response, symbolize_names: true)
  end

  it 'has a nil token as default' do
    api = Danger::CircleAPI.new
    expect(api.circle_token).to be nil
  end

  it 'sets the token on initialize' do
    api = Danger::CircleAPI.new('123456')
    expect(api.circle_token).to eql('123456')
  end

  it 'creates a client with the correct base url' do
    api = Danger::CircleAPI.new
    expect(api.client.url_prefix.to_s).to eql('https://circleci.com/api/v1')
  end

  it 'fetches the build info without token' do
    api = Danger::CircleAPI.new
    allow(api.client).to receive(:get).with(api_path, { 'circle-token' => nil }, accept_json).and_return(@mocked_response)

    expect(api.fetch_build('artsy/eigen', '1500')).to eql(@expected_json_response)
  end

  it 'fetches the build info with token' do
    api = Danger::CircleAPI.new('123456')
    allow(api.client).to receive(:get).with(api_path, { 'circle-token' => '123456' }, accept_json).and_return(@mocked_response)

    expect(api.fetch_build('artsy/eigen', '1500')).to eql(@expected_json_response)
  end
end
