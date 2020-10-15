# coding: utf-8

module Danger
  module RequestSources
    class CodeInsightsAPI
      attr_accessor :report_title, :report_description, :logo_url, :username, :password, :host

      def initialize(project, slug, environment)
        @report_title = environment["DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_TITLE"]
        @report_key = environment["DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY"]
        @report_description = environment["DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_DESCRIPTION"]
        @logo_url = environment["DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_LOGO_URL"]
        @username = environment["DANGER_BITBUCKETSERVER_USERNAME"]
        @password = environment["DANGER_BITBUCKETSERVER_PASSWORD"]
        @host = environment["DANGER_BITBUCKETSERVER_HOST"]
        @project = project
        @slug = slug
      end

      def ready?
        !(@report_title.empty? || @report_description.empty? || @username.empty? || @password.empty? || @host.empty?)
      end

      def delete_report(commit)
        uri = URI(report_endpoint_at_commit(commit))
        request = Net::HTTP::Delete.new(uri.request_uri, {"Content-Type" => "application/json"})
        request.basic_auth @username, @password
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl) do |http|
          http.request(request)
        end

        # show failure when server returns an error
        case response
        when Net::HTTPClientError, Net::HTTPServerError
          # HTTP 4xx - 5xx
          abort "\nError deleting report from Code Insights API: #{response.code} (#{response.message}) - #{response.body}\n\n"
        end

      end

      def send_report(commit, inline_warnings, inline_errors, inline_messages)
        delete_report(commit)
        put_report(commit, inline_errors.count)
        should_post_annotations = !(inline_warnings + inline_errors + inline_messages).empty?
        if should_post_annotations
          post_annotations(commit, inline_warnings, inline_errors, inline_messages)
        end
      end

      def put_report(commit, inline_errors_count)
        uri = URI(report_endpoint_at_commit(commit))
        request = Net::HTTP::Put.new(uri.request_uri, {"Content-Type" => "application/json"})
        request.basic_auth @username, @password
        request.body = {"title": @report_title,
                        "details": @report_description,
                        "result": (inline_errors_count > 0) ? "FAIL" : "PASS",
                        "reporter": @username,
                        "link": "https://github.com/danger/danger",
                        "logoURL": @logo_url
        }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl) do |http|
          http.request(request)
        end

        # show failure when server returns an error
        case response
        when Net::HTTPClientError, Net::HTTPServerError
          # HTTP 4xx - 5xx
          abort "\nError putting report to Code Insights API: #{response.code} (#{response.message}) - #{response.body}\n\n"
        end
      end

      def post_annotations(commit, inline_warnings, inline_errors, inline_messages)
        uri = URI(annotation_endpoint_at_commit(commit))

        annotations = []

        inline_messages.each do |violation|
          annotations << violation_hash_with_severity(violation, "LOW")
        end

        inline_warnings.each do |violation|
          annotations << violation_hash_with_severity(violation, "MEDIUM")
        end

        inline_errors.each do |violation|
          annotations << violation_hash_with_severity(violation, "HIGH")
        end

        body = {annotations: annotations}.to_json
        request = Net::HTTP::Post.new(uri.request_uri, {"Content-Type" => "application/json"})
        request.basic_auth @username, @password
        request.body = body

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl) do |http|
          http.request(request)
        end

        # show failure when server returns an error
        case response
        when Net::HTTPClientError, Net::HTTPServerError
          # HTTP 4xx - 5xx
          abort "\nError posting comment to Code Insights API: #{response.code} (#{response.message}) - #{response.body}\n\n"
        end
      end

      def violation_hash_with_severity(violation, severity)
        annotation = {}
        annotation["message"] = violation.message
        annotation["severity"] = severity
        annotation["path"] = violation.file
        annotation["line"] = violation.line.to_i
        return annotation
      end

      def report_endpoint_at_commit(commit)
        "#{@host}/rest/insights/1.0/projects/#{@project}/repos/#{@slug}/commits/#{commit}/reports/#{@report_key}"
      end

      def annotation_endpoint_at_commit(commit)
        report_endpoint_at_commit(commit) + "/annotations"
      end

      def use_ssl
        @host.include? "https://"
      end

    end
  end
end
