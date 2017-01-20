# coding: utf-8
require "danger/request_sources/github/github_review"

module Danger
  module RequestSources
    module GitHubSource
      class ReviewResolver
        def self.should_submit?(review, event, body)
          return false if same_body?(body, review.body)
          return event_changes_status?(event, review.status)
        end

        private

        def self.event_changes_status?(event, status)
          all_events = [Review::EVENT_APPROVE, Review::EVENT_COMMENT, Review::EVENT_REQUEST_CHANGES]
          all_statuses = [Review::STATUS_APPROVED, Review::STATUS_COMMENTED, Review::STATUS_REQUESTED_CHANGES, Review::STATUS_PENDING]
          return all_events.index(event) != all_statuses.index(status)
        end

        def self.same_body?(body1, body2)
          puts "body1 #{body1} body2 #{body2}"
          return !body1.nil? && !body2.nil? && body1 == body2
        end
      end
    end
  end
end
