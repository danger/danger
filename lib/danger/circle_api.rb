require "rest-client"

module Danger
  class CircleAPI
    attr_accessor :circle_token

    def initialize(circle_token = nil)
      self.circle_token = circle_token
    end

    def fetch_build(repo_slug, build_number)
      url = "https://circleci.com/api/v1/project/#{repo_slug}/#{build_number}"
      params = { :accept => :json, :'circle-token' => circle_token }
      response = RestClient.get url, params
      json = JSON.parse(response, symbolize_names: true)
      json
    end
  end
end
