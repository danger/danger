# https://circleci.com/docs/environment-variables
require 'uri'
require 'danger/ci_source/circle_api'

module Danger
  module CISource
    class CircleCI < CI
      def self.validates?(env)
        return false if env["CIRCLE_BUILD_NUM"].nil?
        return true unless env["CI_PULL_REQUEST"].nil?

        return !env["CIRCLE_PROJECT_USERNAME"].nil? && !env["CIRCLE_PROJECT_REPONAME"].nil?
      end

      def supported_request_sources
        @supported_request_sources ||= [Danger::RequestSources::GitHub]
      end

      def client
        @client ||= CircleAPI.new(@circle_token)
      end

      def fetch_pull_request_url(repo_slug, build_number)
        build_json = client.fetch_build(repo_slug, build_number)
        build_json[:pull_request_urls].first
      end

      def pull_request_url(env)
        url = env["CI_PULL_REQUEST"]

        if url.nil? && !env["CIRCLE_PROJECT_USERNAME"].nil? && !env["CIRCLE_PROJECT_REPONAME"].nil?
          repo_slug = env["CIRCLE_PROJECT_USERNAME"] + "/" + env["CIRCLE_PROJECT_REPONAME"]
          url = fetch_pull_request_url(repo_slug, env["CIRCLE_BUILD_NUM"])
        end

        url
      end

      def initialize(env)
        @circle_token = env["CIRCLE_CI_API_TOKEN"]
        url = pull_request_url(env)

        if URI.parse(url).path.split("/").count == 5
          paths = URI.parse(url).path.split("/")
          # The first one is an extra slash, ignore it
          self.repo_slug = paths[1] + "/" + paths[2]
          self.pull_request_id = paths[4]
        end
      end
    end
  end
end
