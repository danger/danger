# frozen_string_literal: true

require_relative "gitlab_config"

module Danger
  module OutputRegistry
    module Handlers
      module GitLab
        # Posts violations as a consolidated MR comment (note).
        #
        # This handler extracts violations and posts them as a single comment
        # on the merge request. It manages comment lifecycle including creation,
        # updates, and deletion.
        #
        # @example
        #   handler = GitLabCommentHandler.new(context, violations)
        #   handler.execute if handler.enabled?
        #
        class GitLabCommentHandler < OutputHandler
          # Executes the handler to post MR comments.
          #
          # @return [void]
          #
          def execute
            return unless has_violations?

            request_source = context.env.request_source
            return unless request_source.kind_of?(::Danger::RequestSources::GitLab)

            comment_violations = filter_comment_violations
            comment_body = generate_comment_body(comment_violations)
            return if comment_body.nil? || comment_body.empty?

            post_or_update_comment(request_source, comment_body)
          end

          protected

          # Filters violations suitable for MR comment (non-inline).
          #
          # @return [Hash] Hash with warnings, errors, messages keys
          #
          def filter_comment_violations
            filter_violations { |v| v.file.nil? }
          end

          # Generates the comment body.
          #
          # @param violations [Hash] Violations to include in comment
          # @return [String, nil] Comment body, or nil if no violations
          #
          def generate_comment_body(violations)
            return nil if violations.values.all?(&:empty?)

            parts = [GitLabConfig::MR_REVIEW_HEADER]

            if violations[:errors].any?
              parts << ""
              parts << "## :no_entry_sign: #{GitLabConfig::ERRORS_SECTION_TITLE}"
              parts << ""
              violations[:errors].each { |error| parts << "- #{error.message}" }
            end

            if violations[:warnings].any?
              parts << ""
              parts << "## :warning: #{GitLabConfig::WARNINGS_SECTION_TITLE}"
              parts << ""
              violations[:warnings].each { |warning| parts << "- #{warning.message}" }
            end

            if violations[:messages].any?
              parts << ""
              parts << "## :book: #{GitLabConfig::MESSAGES_SECTION_TITLE}"
              parts << ""
              violations[:messages].each { |message| parts << "- #{message.message}" }
            end

            parts.join("\n")
          end

          # Posts or updates the comment on the MR.
          #
          # @param request_source [Danger::RequestSources::GitLab] The GitLab request source
          # @param comment_body [String] The comment body
          # @return [void]
          #
          def post_or_update_comment(request_source, comment_body)
            client = request_source.client
            repo_slug = request_source.ci_source.repo_slug
            mr_id = request_source.ci_source.pull_request_id

            existing_comments = fetch_danger_comments(request_source)
            previous_comment = existing_comments.last

            if previous_comment
              client.edit_merge_request_note(repo_slug, mr_id, previous_comment[:id], comment_body)
            else
              client.create_merge_request_note(repo_slug, mr_id, comment_body)
            end
          rescue StandardError => e
            log_warning("Failed to post comment: #{e.message}")
          end

          # Fetches existing Danger-generated comments.
          #
          # @param request_source [Danger::RequestSources::GitLab] The request source
          # @return [Array<Hash>] Array of comment hashes
          #
          def fetch_danger_comments(request_source)
            client = request_source.client
            repo_slug = request_source.ci_source.repo_slug
            mr_id = request_source.ci_source.pull_request_id

            comments = client.merge_request_comments(repo_slug, mr_id, per_page: 100).auto_paginate

            comments.filter_map do |comment|
              next unless comment.body.include?(GitLabConfig::MR_REVIEW_HEADER)

              { id: comment.id, body: comment.body }
            end
          rescue StandardError
            []
          end
        end
      end
    end
  end
end
