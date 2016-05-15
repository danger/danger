require 'faraday'

module Danger
  class CircleAPI
    attr_accessor :circle_token

    def initialize(circle_token = nil)
      self.circle_token = circle_token
    end

    def client
      @client ||= Faraday.new(url: 'https://circleci.com/api/v1')
    end

    def fetch_build(repo_slug, build_number)
      url = "project/#{repo_slug}/#{build_number}"
      params = { 'circle-token' => circle_token }
      response = client.get url, params, accept: 'application/json'
      json = JSON.parse(response.body, symbolize_names: true)
      json
    end
  end
end
