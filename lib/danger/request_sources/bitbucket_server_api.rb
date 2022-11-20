# frozen_string_literal: true

require "openssl"
require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class BitbucketServerAPI
      attr_accessor :host, :verify_ssl, :pr_api_endpoint, :key, :project

      def initialize(project, slug, pull_request_id, environment)
        @username = environment["DANGER_BITBUCKETSERVER_USERNAME"]
        @password = environment["DANGER_BITBUCKETSERVER_PASSWORD"]
        self.host = environment["DANGER_BITBUCKETSERVER_HOST"]
        self.verify_ssl = environment["DANGER_BITBUCKETSERVER_VERIFY_SSL"] != "false"
        if self.host && !(self.host.include? "http://") && !(self.host.include? "https://")
          self.host = "https://" + self.host
        end
        self.key = slug
        self.project = project
        self.pr_api_endpoint = "#{host}/rest/api/1.0/projects/#{project}/repos/#{slug}/pull-requests/#{pull_request_id}"
      end

      def inspect
        inspected = super

        inspected.gsub!(@password, "********") if @password

        inspected
      end

      def credentials_given?
        @username && !@username.empty? && @password && !@password.empty?
      end

      def pull_request(*)
        fetch_pr_json
      end

      def fetch_pr_json
        uri = URI(pr_api_endpoint)
        fetch_json(uri)
      end

      def fetch_pr_diff
        uri = URI("#{pr_api_endpoint}/diff?withComments=false")
        fetch_json(uri)
      end

      def fetch_last_comments
        uri = URI("#{pr_api_endpoint}/activities?limit=1000")
        fetch_json(uri)[:values].select { |v| v[:action] == "COMMENTED" }.map { |v| v[:comment] }
      end

      def delete_comment(id, version)
        uri = URI("#{pr_api_endpoint}/comments/#{id}?version=#{version}")
        delete(uri)
      end

      def post_comment(text)
        uri = URI("#{pr_api_endpoint}/comments")
        body = { text: text }.to_json
        post(uri, body)
      end

      def update_pr_build_status(status, changeset, build_job_link, description)
        uri = URI("#{self.host}/rest/build-status/1.0/commits/#{changeset}")
        body = build_status_body(status, build_job_link, description)
        post(uri, body)
      end

      private

      def use_ssl
        return self.pr_api_endpoint.include? "https://"
      end

      def fetch_json(uri)
        req = Net::HTTP::Get.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        res = http(uri).start do |http|
          http.request(req)
        end
        JSON.parse(res.body, symbolize_names: true)
      end

      def post(uri, body)
        req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        req.body = body

        res = http(uri).start do |http|
          http.request(req)
        end

        # show error to the user when Bitbucket Server returned an error
        case res
        when Net::HTTPClientError, Net::HTTPServerError
          # HTTP 4xx - 5xx
          abort "\nError posting comment to Bitbucket Server: #{res.code} (#{res.message}) - #{res.body}\n\n"
        end
      end

      def delete(uri)
        req = Net::HTTP::Delete.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.basic_auth @username, @password
        http(uri).start do |http|
          http.request(req)
        end
      end

      def http(uri)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = use_ssl
        http.verify_mode = verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        http
      end

      def build_status_body(status, build_job_link, description)
        body = {}
        body["state"] = status
        body["key"] = self.key
        body["url"] = build_job_link
        body["description"] = description if description
        return body.to_json
      end
    end
  end
end
