# coding: utf-8
require "octokit"

module Octokit
  class Client
    # The Pull Request Review API is currently available for developers to preview.
    # During the preview period, the API may change without advance notice.
    # please see the blog post for full details.
    # To access the API during the preview period, you must provide
    # a custom media type in the Accept header:
    CUSTOM_ACCEPT_HEADER = "application/vnd.github.black-cat-preview+json".freeze

    # Approve pull request event
    PULL_REQUEST_REVIEW_EVENT_APPROVE = "APPROVE".freeze

    # Request changes on the pull request event
    PULL_REQUEST_REVIEW_EVENT_REQUEST_CHANGES = "REQUEST_CHANGES".freeze

    # Left a gemeneral comment on the pull request event
    PULL_REQUEST_REVIEW_EVENT_COMMENT = "COMMENT".freeze

    # List pull request reviews for a pull request
    #
    # @see https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
    # @param repo [Integer, String, Hash, Repository] A GitHub repository
    # @param pull_request_number [Integer] Number of the pull request to fetch reviews for
    # @return [Array<Sawyer::Resource>] Array of reviews
    # @example
    #   Octokit.pull_request_reviews('rails/rails', :state => 'closed')
    def pull_request_reviews(repo, pull_request_number, options = {})
      accept = {
        accept: CUSTOM_ACCEPT_HEADER
      }
      paginate "#{Repository.path repo}/pulls/#{pull_request_number}/reviews", options.merge(accept)
    end

    # Create a pull request review
    #
    # @see https://developer.github.com/v3/pulls/reviews/#create-a-pull-request-review
    # @param repo [Integer, String, Hash, Repository] A GitHub repository
    # @param pull_request_number [Integer] Number of the pull request to create review for
    # @param event [String] The review action (event) to perform. Can be one of
    #                       PULL_REQUEST_REVIEW_EVENT_APPROVE
    #                       PULL_REQUEST_REVIEW_EVENT_REQUEST_CHANGES
    #                       PULL_REQUEST_REVIEW_EVENT_COMMENT
    # @param body [String] The body for the pull request review (optional). Supports GFM.
    # @return [Sawyer::Resource] The newly created pull request
    # @example
    #   @client.create_pull_request_review("octokit/octokit.rb", "APPROVE", "Thanks for your contribution")
    def create_pull_request_review(repo, pull_request_number, event, body = nil, options = {})
      review = {
        event: event,
        accept: CUSTOM_ACCEPT_HEADER
      }
      review[:body] = body unless body.nil?
      post "#{Repository.path repo}/pulls/#{pull_request_number}/reviews", options.merge(review)
    end

    # Submit a pull request review
    #
    # @see https://developer.github.com/v3/pulls/reviews/#create-a-pull-request-review
    # @param repo [Integer, String, Hash, Repository] A GitHub repository
    # @param pull_request_number [Integer] Number of the pull request to create review for
    # @param review_id [Integer] ID of the pull request review to submit
    # @param event [String] The review action (event) to perform. Can be one of
    #                       PULL_REQUEST_REVIEW_EVENT_APPROVE
    #                       PULL_REQUEST_REVIEW_EVENT_REQUEST_CHANGES
    #                       PULL_REQUEST_REVIEW_EVENT_COMMENT
    # @param body [String] The body for the pull request review (optional). Supports GFM.
    # @return [Sawyer::Resource] The newly created pull request
    # @example
    #   @client.submit_pull_request_review("octokit/octokit.rb", "REQUEST_CHANGES",
    #                                      "Nice changes, but please make couple of imrovements")
    def submit_pull_request_review(repo, pull_request_number, review_id, event, body = nil, options = {})
      review = {
        event: event,
        accept: CUSTOM_ACCEPT_HEADER
      }
      review[:body] = body unless body.nil?
      post "#{Repository.path repo}/pulls/#{pull_request_number}/reviews/#{review_id}/events", options.merge(review)
    end
  end
end
