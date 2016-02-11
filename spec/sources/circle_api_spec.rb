require 'spec_helper'
require 'danger/circle_api'

describe Danger::CircleAPI do
  api_url = "https://circleci.com/api/v1/project/artsy/eigen/1500"

  it 'has a nil token as default' do
    client = Danger::CircleAPI.new
    expect(client.circle_token).to be nil
  end

  it 'sets the token on initialize' do
    client = Danger::CircleAPI.new('123456')
    expect(client.circle_token).to eql('123456')
  end

  it 'fetches the build info without token' do
    client = Danger::CircleAPI.new
    build_response = fixture("circle_build_response")
    allow(RestClient).to receive(:get).with(api_url, { :accept => :json, :'circle-token' => nil }).and_return(build_response)

    expect(client.fetch_build("artsy/eigen", "1500")).to eql(JSON.parse(build_response, symbolize_names: true))
  end

  it 'fetches the build info with token' do
    client = Danger::CircleAPI.new('123456')
    build_response = fixture("circle_build_response")
    allow(RestClient).to receive(:get).with(api_url, { :accept => :json, :'circle-token' => '123456' }).and_return(build_response)

    expect(client.fetch_build("artsy/eigen", "1500")).to eql(JSON.parse(build_response, symbolize_names: true))
  end
end
