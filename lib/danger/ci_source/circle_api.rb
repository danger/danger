require "faraday"

module Danger
  class CircleAPI
    attr_accessor :circle_token

    def initialize(circle_token = nil)
      self.circle_token = circle_token
    end

    # Determine if there's a PR attached to this commit,
    # and return a bool
    def pull_request?(env)
      url = pull_request_url(env)
      return !url.nil?
    end

    # Determine if there's a PR attached to this commit,
    # and return the url if so
    def pull_request_url(env)
      url = env["CI_PULL_REQUEST"]

      if url.nil? && !env["CIRCLE_PROJECT_USERNAME"].nil? && !env["CIRCLE_PROJECT_REPONAME"].nil?
        repo_slug = env["CIRCLE_PROJECT_USERNAME"] + "/" + env["CIRCLE_PROJECT_REPONAME"]
        url = fetch_pull_request_url(repo_slug, env["CIRCLE_BUILD_NUM"])
      end
      url
    end

    def client
      @client ||= Faraday.new(url: "https://circleci.com/api/v1")
    end

    # Ask the API if the commit is inside a PR
    def fetch_pull_request_url(repo_slug, build_number)
      build_json = client.fetch_build(repo_slug, build_number)
      build_json[:pull_request_urls].first
    end

    # Make the API call, and parse the JSON
    def fetch_build(repo_slug, build_number)
      url = "project/#{repo_slug}/#{build_number}"
      params = { "circle-token" => circle_token }
      response = client.get url, params, accept: "application/json"
      json = JSON.parse(response.body, symbolize_names: true)
      json
    end
  end
end
