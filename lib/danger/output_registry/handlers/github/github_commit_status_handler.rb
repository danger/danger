# frozen_string_literal: true

require_relative "github_config"
require "danger/helpers/comments_helper"

module Danger
  module OutputRegistry
    module Handlers
      module GitHub
        # Posts commit status to GitHub based on violations.
        #
        # This handler sets the commit status (success/failure) on the PR HEAD
        # based on whether there are any errors in the violations.
        #
        # Supports the following options:
        # - danger_id: Used in the status context (e.g., "danger/my-danger")
        #
        # @example
        #   handler = GitHubCommitStatusHandler.new(context, violations, danger_id: "my-danger")
        #   handler.execute if handler.enabled?
        #
        class GitHubCommitStatusHandler < OutputHandler
          include Danger::Helpers::CommentsHelper

          # Executes the handler to post commit status.
          #
          # @return [void]
          #
          def execute
            return unless context.kind_of?(::Danger::RequestSources::GitHub)

            status = errors.any? ? "failure" : "success"
            description = generate_description(warnings: warnings, errors: errors, template: "github")
            post_commit_status(status, description)
          end

          protected

          # Posts the commit status to GitHub.
          #
          # @param status [String] Status: "success" or "failure"
          # @param description [String] Status description
          # @return [void]
          #
          def post_commit_status(status, description)
            commit_sha = context.pr_json["head"]["sha"]

            context.client.create_status(
              context.ci_source.repo_slug,
              commit_sha,
              status,
              context: "danger/#{danger_id}",
              description: description.to_s[0, GitHubConfig::COMMIT_STATUS_MAX_LENGTH]
            )
          rescue Octokit::NotFound, Octokit::Unauthorized => e
            handle_status_error(e, status)
          rescue StandardError => e
            log_warning("Failed to post commit status: #{e.message}")
          end

          # Handles errors when posting commit status.
          #
          # When we can't set status (usually due to missing permissions), we need
          # to fail the build if there are errors so CI still catches issues.
          #
          # @param error [StandardError] The error that occurred
          # @param status [String] The intended status
          # @return [void]
          #
          def handle_status_error(error, status)
            if status == "failure" && errors.any?
              is_private = context.pr_json["base"]["repo"]["private"]
              if is_private
                abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)} and I don't have write access to the PR to set a PR status.")
              else
                abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)}.")
              end
            else
              log_warning("Unable to post commit status (#{error.message}). Danger does not have write access to the PR.")
            end
          end
        end
      end
    end
  end
end
