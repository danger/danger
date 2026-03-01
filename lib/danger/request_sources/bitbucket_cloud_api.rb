# coding: utf-8

require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class BitbucketCloudAPI
      attr_accessor :host, :pr_api_endpoint, :pr_api_endpoint_v1

      def initialize(project, slug, pull_request_id, environment)
        @username = environment["DANGER_BITBUCKETCLOUD_USERNAME"]
        @password = environment["DANGER_BITBUCKETCLOUD_PASSWORD"]
        self.pr_api_endpoint = "https://api.bitbucket.org/2.0/repositories/#{project}/#{slug}/pullrequests/#{pull_request_id}"
        self.pr_api_endpoint_v1 = "https://api.bitbucket.org/1.0/repositories/#{project}/#{slug}/pullrequests/#{pull_request_id}"
      end

      def inspect
        inspected = super

        if @password
          inspected = inspected.sub! @password, "********".freeze
        end

        inspected
      end

      def credentials_given?
        @username && !@username.empty? && @password && !@password.empty?
      end

      def fetch_pr_json
        uri = URI(pr_api_endpoint)
        fetch_json(uri)
      end

      def fetch_last_comments
        uri = URI("#{pr_api_endpoint}/activity?limit=1000")
        fetch_json(uri)[:values].select { |v| v[:comment] }.map { |v| v[:comment] }
      end

      def delete_comment(id)
        uri = URI("#{pr_api_endpoint_v1}/comments/#{id}")
        delete(uri)
      end

      def post_comment(text)
        uri = URI("#{pr_api_endpoint_v1}/comments")
        body = { content: text }.to_json
        post(uri, body)
      end

      private

      def fetch_json(uri)
        req = Net::HTTP::Get.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
        JSON.parse(res.body, symbolize_names: true)
      end

      def post(uri, body)
        req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        req.body = body
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
      end

      def delete(uri)
        req = Net::HTTP::Delete.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
      end
    end
  end
end
