# coding: utf-8

require "danger/request_sources/github/github_review"

module Danger
  module RequestSources
    module GitHubSource
      class ReviewResolver
        def self.should_submit?(review, body)
          return !same_body?(body, review.body)
        end

        def self.same_body?(body1, body2)
          return !body1.nil? && !body2.nil? && body1 == body2
        end
      end
    end
  end
end
