# coding: utf-8
require "octokit"

module Danger
  module RequestSources
    class GitHubReview
      REVIEW_EVENT_APPROVE = "APPROVE"
      REVIEW_EVENT_REQUEST_CHANGES = "REQUEST_CHANGES"
      REVIEW_EVENT_COMMENT = "COMMENT"

      DANGER_REVIEW_STATE_INITIAL = "INITIAL"
      DANGER_REVIEW_STATE_STARTED = "STARTED"
      DANGER_REVIEW_STATE_SUBMITTED = "SUBMITTED"

      attr_accessor :review_json :comments :danger_state :inline_comments :comments

      def initialize(ci_source, client, pr_json, review_json = nil)
        @pr_json = pr_json
        @client = client
        @ci_source =
        self.danger_state = DANGER_REVIEW_STATE_INITIAL
        self.review_json = review_json
      end

      def start
        raise "Review has been already started, please submit the ongoing review before starting again" if started?
        self.review_json ||= @client.post(reviews_url)
        self.danger_state = DANGER_REVIEW_STATE_STARTED
      end

      def submit
        raise "Review has not started yet, please call github.review.start first" unless started?
        raise "Review has been started submutted, please call start it again" if submitted?
        @client.post(reviews_url)
        self.danger_state = DANGER_REVIEW_STATE_SUBMITTED
      end

      def generated_by_danger?(danger_id = "danger")
        self.review_json["body"].include?("generated_by_#{danger_id}")
      end

      def inline_comment(path, position, body)

      end

      def comment(body)

      end

      def inline_comments
        @inline_comments ||= begin
          @client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
            .map { |comment| Comment.from_github(comment).generated_by_danger?("danger") }
        end
      end

      private

      def started?
        return self.danger_state == DANGER_REVIEW_STATE_STARTED
      end

      def submitted?
        return self.danger_state == DANGER_REVIEW_STATE_SUBMITTED
      end

      def pr_url
        @pr_json["url"]
      end

      def reviews_url
        pr_url + "/reviews"
      end
    end
  end
end
