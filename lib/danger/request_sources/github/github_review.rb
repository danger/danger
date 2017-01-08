# coding: utf-8
require "octokit"
require "danger/ci_source/ci_source"
require "danger/request_sources/github/octokit_pr_review"
require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

module Danger
  module RequestSources
    class GitHubReview
      include Danger::Helpers::CommentsHelper

      GITHUB_REVIEW_EVENT_APPROVE = "APPROVE"
      GITHUB_REVIEW_EVENT_REQUEST_CHANGES = "REQUEST_CHANGES"

      attr_accessor :review_json

      def initialize(client, ci_source, review_json = nil)
        @ci_source = ci_source
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
        puts "Warnings :#{@warnings}"
        puts "Errors :#{@errors}"
        puts "Messages :#{@messages}"
        puts "Markdowns :#{@markdowns}"
        if exist_on_remote?
          self.review_json = @client.submit_pull_request_review(@ci_source.repo_slug, @ci_source.pull_request_id, id, generate_github_review_event, generate_body)
        else
          self.review_json = @client.create_pull_request_review(@ci_source.repo_slug, @ci_source.pull_request_id, generate_github_review_event, generate_body)
        end
      end

      def generated_by_danger?(danger_id = "danger")
        self.review_json["body"].include?("generated_by_#{danger_id}")
      end

      def message(message, sticky=true, file=nil, line=nil)
        @messages << Violation.new(message, sticky, file, line)
      end

      def warn(message, sticky=true, file=nil, line=nil)
        @warnings << Violation.new(message, sticky, file, line)
      end

      def fail(message, sticky=true, file=nil, line=nil)
        @errors << Violation.new(message, sticky, file, line)
      end

      def markdown(message, file=nil, line=nil)
        @markdowns << Markdown.new(message, file, line)
      end

      def exist_on_remote?
        self.review_json != nil
      end

      def id
        self.review_json["id"]
      end

      def body
        return "" if self.review_json.nil?
        self.review_json["body"]
      end

      private

      def generate_github_review_event
        has_general_violations? ? GITHUB_REVIEW_EVENT_REQUEST_CHANGES : GITHUB_REVIEW_EVENT_APPROVE
      end

      def generate_body(danger_id: "danger")
        previous_violations = parse_comment(body)
        general_violations = generate_general_violations
        return "" unless has_general_violations?(general_violations)

        new_body = generate_comment(warnings: general_violations[:warnings],
                                    errors: general_violations[:errors],
                                    messages: general_violations[:messages],
                                    markdowns: general_violations[:markdowns],
                                    previous_violations: previous_violations,
                                    danger_id: danger_id,
                                    template: "github")
        return new_body
      end

      def generate_general_violations
        general_warnings = @warnings.reject(&:inline?)
        general_markdowns = @markdowns.reject(&:inline?)
        general_errors = @errors.reject(&:inline?)
        general_messages = @messages.reject(&:inline?)
        {
          warnings: general_warnings,
          markdowns: general_markdowns,
          errors: general_errors,
          messages: general_messages
        }
      end

      def has_general_violations?(general_violations = generate_general_violations)
        return !(general_violations[:warnings] + general_violations[:markdowns] + general_violations[:errors] + general_violations[:messages]).empty?
      end
    end
  end
end
