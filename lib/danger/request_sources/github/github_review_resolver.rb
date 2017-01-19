# coding: utf-8
require "danger/request_sources/github/github_review"

module Danger
  module GitHub
    class ReviewResolver
      def initialize(review)
        @review = review
      end

      def should_submit?(event, body)
        return false if bodies_same?(@review.body, body) || @review.status != Review::STATUS_REQUESTED_CHANGES
        return true
      end

      def should_create?(event, body)
        return false if bodies_same?(@review.body, body)
        return true if @review.status == Review::STATUS_PENDING
        return true if @review.status == Review::STATUS_APPROVED && event != Review::EVENT_APPROVE
        return false
      end

      private

      def bodies_same?(current_body, new_body)
        return !new_body.nil? && !current_body.nil? && new_body == current_body
      end
    end
  end
end
