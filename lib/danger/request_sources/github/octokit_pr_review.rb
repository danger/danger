# coding: utf-8
require "octokit"

module Octokit
  class Client
    module PullRequestsReview

      # The Pull Request Review API is currently available for developers to preview.
      # During the preview period, the API may change without advance notice.
      # please see the blog post for full details.
      # To access the API during the preview period, you must provide
      # a custom media type in the Accept header:
      CUSTOM_ACCEPT_HEADER = "application/vnd.github.black-cat-preview+json"

      # List pull request reviews for a pull request
      #
      # @overload pull_request_reviews(repo, options)
      #   @param repo [Integer, String, Hash, Repository] A GitHub repository
      #   @param pull_request_number [Integer] Number of the pull request to fetch reviews for
      # @return [Array<Sawyer::Resource>] Array of reviews
      # @see https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
      # @example
      #   Octokit.pull_request_reviews('rails/rails', :state => 'closed')
      def pull_request_reviews(repo, pull_request_number, options = {})
        accept = {
          :accept => CUSTOM_ACCEPT_HEADER
        }
        paginate "#{Repository.path repo}/pulls/reviews", options.merge(accept)
      end

    end
  end
end
