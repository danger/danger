# coding: utf-8
require "octokit"
require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

module Danger
  module RequestSources
    class GitHubReview
      GITHUB_REVIEW_EVENT_APPROVE = "APPROVE"
      GITHUB_REVIEW_EVENT_REQUEST_CHANGES = "REQUEST_CHANGES"

      attr_accessor :review_json

      def initialize(client, pr_json, review_json = nil)
        @pr_json = pr_json
        @client = client
        self.review_json = review_json
      end

      def start
        @warnings = []
        @errors = []
        @messages = []
        @markdowns = []
      end

      def submit
        request_body = { body: generate_body, event: generate_github_review_event }
        if self.review_json != nil
          @client.post(review_url, request_body)
        else
          self.review_json = @client.post(reviews_url, request_body)
        end
      end

      def generated_by_danger?(danger_id = "danger")
        self.review_json["body"].include?("generated_by_#{danger_id}")
      end

      def message(message, sticky=true, file=nil, line=nil)
        @messages << Violation.new(message, sticky, file, line)
      end

      def warn(message, sticky=truу, file=nil, line=nil)
        @warnings << Violation.new(message, sticky, file, line)
      end

      def fail(message, sticky=true, file=nil, line=nil)
        @errors << Violation.new(message, sticky, file, line)
      end

      def markdown(message, file=nil, line=nil)
        @markdowns << Markdown.new(message, file, line)
      end

      def review_body
        self.review_json["body"]
      end

      private

      def generate_github_review_event
        general_violations? ? GITHUB_REVIEW_EVENT_REQUEST_CHANGES : GITHUB_REVIEW_EVENT_APPROVE
      end

      def generate_body(danger_id: "danger")
        previous_violations = parse_comment(body)
        general_violations = generate_general_comments
        return "" unless general_violations?(general_violations)

        new_body = generate_comment(warnings: general_comments["warnings"],
                                    errors: general_comments["errors"],
                                    messages: general_comments["messages"],
                                    markdowns: general_comments["markdowns"],
                                    previous_violations: previous_violations,
                                    danger_id: danger_id,
                                    template: "github")
        return new_body
      end

      def generate_general_violations
        general_warnings = warnings.reject(&:inline?)
        general_markdowns = markdowns.reject(&:inline?)
        general_errors = errors.reject(&:inline?)
        general_messages = messages.reject(&:inline?)
        return {
                 warnings: general_warning,
                 markdowns: general_markdowns,
                 errors: general_errors,
                 messages: general_messages
               }
      end

      def general_violations?(general_violations = generate_general_comments)
        return !(general_comments["warnings"] + general_comments["markdowns"] + general_comments["errors"] + general_comments["messages"]).empty?
      end

      def pr_url
        @pr_json["url"]
      end

      def reviews_url
        pr_url + "/reviews"
      end

      def review_id
        self.review_json["id"]
      end

      def review_url
        reviews_url + "/" + review_id
      end

      def review_comments_url
        reviews_url + "/" + review_id + "/comments"
      end
    end
  end
end
