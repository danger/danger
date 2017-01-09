# coding: utf-8
require "danger/request_sources/github/github_review"

module Danger
  module GitHub
    class ReviewResolver
      def initialize(review)
        @review = review
      end

      def should_submit?(event)
        return true if @review.status == Review::STATUS_REQUESTED_CHANGES
        return false
      end

      def should_create?(event)
        return true if @review.status == Review::STATUS_PENDING
        return true if @review.status == Review::STATUS_APPROVED && event != Review::EVENT_APPROVE
        return false
      end
    end
  end
end
