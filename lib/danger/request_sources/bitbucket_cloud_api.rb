# coding: utf-8

require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class BitbucketCloudAPI
      attr_accessor :project, :slug, :pull_request_id

      def initialize(repo_slug, pull_request_id, branch_name, environment)
        @username = environment["DANGER_BITBUCKETCLOUD_USERNAME"]
        @password = environment["DANGER_BITBUCKETCLOUD_PASSWORD"]
        self.project, self.slug = repo_slug.split("/")
        self.pull_request_id = pull_request_id || fetch_pr_from_branch(branch_name)
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

      def base_url(version)
        "https://api.bitbucket.org/#{version}.0/repositories/#{project}/#{slug}/pullrequests"
      end

      def pr_api_endpoint
        "#{base_url(2)}/#{pull_request_id}"
      end

      def pr_api_endpoint_v1
        "#{base_url(1)}/#{pull_request_id}"
      end

      def prs_api_endpoint(branch_name)
        "#{base_url(2)}?q=source.branch.name=\"#{branch_name}\""
      end

      def fetch_pr_from_branch(branch_name)
        uri = URI(URI.escape(prs_api_endpoint(branch_name)))
        fetch_json(uri)[:values][0][:id]
      end

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
