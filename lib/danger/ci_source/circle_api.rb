require "faraday"

module Danger
  class CircleAPI
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
        if !env["CIRCLE_PR_NUMBER"].nil?
          host = env["DANGER_GITHUB_HOST"] || "github.com"
          url = "https://" + host + "/" + repo_slug + "/pull/" + env["CIRCLE_PR_NUMBER"]
        else
          token = env["DANGER_CIRCLE_CI_API_TOKEN"]
          url = fetch_pull_request_url(repo_slug, env["CIRCLE_BUILD_NUM"], token)
        end
      end
      url
    end

    def client
      @client ||= Faraday.new(url: "https://circleci.com/api/v1")
    end

    # Ask the API if the commit is inside a PR
    def fetch_pull_request_url(repo_slug, build_number, token)
      build_json = fetch_build(repo_slug, build_number, token)
      pull_requests = build_json[:pull_requests]
      return nil unless pull_requests.first
      pull_requests.first[:url]
    end

    # Make the API call, and parse the JSON
    def fetch_build(repo_slug, build_number, token)
      url = "project/#{repo_slug}/#{build_number}"
      params = { "circle-token" => token }
      response = client.get url, params, accept: "application/json"
      json = JSON.parse(response.body, symbolize_names: true)
      json
    end
  end
end
