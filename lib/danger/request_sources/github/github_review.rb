# coding: utf-8

require "octokit"
require "danger/ci_source/ci_source"
require "danger/request_sources/github/github_review_resolver"
require "danger/danger_core/messages/violation"
require "danger/danger_core/messages/markdown"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

module Danger
  module RequestSources
    module GitHubSource
      class Review
        include Danger::Helpers::CommentsHelper

        # @see https://developer.github.com/v3/pulls/reviews/ for all possible events
        EVENT_APPROVE = "APPROVE".freeze
        EVENT_REQUEST_CHANGES = "REQUEST_CHANGES".freeze
        EVENT_COMMENT = "COMMENT".freeze

        # Current review status, if the review has not been submitted yet -> STATUS_PENDING
        STATUS_APPROVED = "APPROVED".freeze
        STATUS_REQUESTED_CHANGES = "CHANGES_REQUESTED".freeze
        STATUS_COMMENTED = "COMMENTED".freeze
        STATUS_PENDING = "PENDING".freeze

        attr_reader :id, :body, :status, :review_json

        def initialize(client, ci_source, review_json = nil)
          @ci_source = ci_source
          @client = client
          @review_json = review_json
        end

        def id
          return nil unless self.review_json
          self.review_json["id"]
        end

        def body
          return "" unless self.review_json
          self.review_json["body"]
        end

        def status
          return STATUS_PENDING if self.review_json.nil?
          return self.review_json["state"]
        end

        # Starts the new review process
        def start
          @warnings = []
          @errors = []
          @messages = []
          @markdowns = []
        end

        # Submits the prepared review
        def submit
          general_violations = generate_general_violations
          submission_body = generate_body

          # If the review resolver says that there is nothing to submit we skip submission
          return unless ReviewResolver.should_submit?(self, submission_body)

          @review_json = @client.create_pull_request_review(@ci_source.repo_slug, @ci_source.pull_request_id, event: generate_event(general_violations), body: submission_body)
        end

        def generated_by_danger?(danger_id = "danger")
          self.review_json["body"].include?("generated_by_#{danger_id}")
        end

        def message(message, sticky = true, file = nil, line = nil)
          @messages << Violation.new(message, sticky, file, line)
        end

        def warn(message, sticky = true, file = nil, line = nil)
          @warnings << Violation.new(message, sticky, file, line)
        end

        def fail(message, sticky = true, file = nil, line = nil)
          @errors << Violation.new(message, sticky, file, line)
        end

        def markdown(message, file = nil, line = nil)
          @markdowns << Markdown.new(message, file, line)
        end

        private

        # The only reason to request changes for the PR is to have errors from Danger
        # otherwise let's just notify user and we're done
        def generate_event(violations)
          violations[:errors].empty? ? EVENT_APPROVE : EVENT_REQUEST_CHANGES
        end

        def generate_body(danger_id: "danger")
          previous_violations = parse_comment(body)
          general_violations = generate_general_violations
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
          general_errors = @errors.reject(&:inline?)
          general_messages = @messages.reject(&:inline?)
          general_markdowns = @markdowns.reject(&:inline?)
          {
            warnings: general_warnings,
            markdowns: general_markdowns,
            errors: general_errors,
            messages: general_messages
          }
        end
      end
    end
  end
end
