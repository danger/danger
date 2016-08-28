# coding: utf-8
require "gitlab"
require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class GitLab < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :mr_json, :commits_json

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        @token = @environment["DANGER_GITLAB_API_TOKEN"]
      end

      def client
        token = @environment["DANGER_GITLAB_API_TOKEN"]
        raise "No API token given, please provide one using `DANGER_GITLAB_API_TOKEN`" unless token
        params = { private_token: token }
        params[:endpoint] = endpoint

        @client ||= Gitlab.client(params)
      end

      def validates_as_api_source?
        @token && !@token.empty?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def endpoint
        @endpoint ||= @environment["DANGER_GITLAB_API_BASE_URL"] || "https://gitlab.com/api/v3"
      end

      def host
        @host ||= @environment["DANGER_GITLAB_HOST"] || "gitlab.com"
      end

      def base_commit
        first_commit_in_branch = self.commits_json.last.id
        @base_comit ||= self.scm.exec "rev-parse #{first_commit_in_branch}^1"
      end

      def mr_comments
        @comments ||= client.merge_request_comments(escaped_ci_slug, ci_source.pull_request_id)
                            .map { |comment| Comment.from_gitlab(comment) }
      end

      def mr_diff
        @mr_diff ||= client.merge_request_changes(escaped_ci_slug, ci_source.pull_request_id)
                           .changes.map { |change| change["diff"] }.join("\n")
      end

      def escaped_ci_slug
        @escaped_ci_slug ||= CGI.escape(ci_source.repo_slug)
      end

      def setup_danger_branches
        head_commit = self.scm.head_commit

        # Next, we want to ensure that we have a version of the current branch at a known location
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def fetch_details
        self.mr_json = client.merge_request(escaped_ci_slug, self.ci_source.pull_request_id)
        self.commits_json = client.merge_request_commits(escaped_ci_slug, self.ci_source.pull_request_id)
        self.ignored_violations = ignored_violations_from_pr(self.mr_json)
      end

      def ignored_violations_from_pr(mr_json)
        pr_body = mr_json.description
        return [] if pr_body.nil?
        pr_body.chomp.scan(/>\s*danger\s*:\s*ignore\s*"(.*)"/i).flatten
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger")
        editable_comments = mr_comments.select { |comment| comment.generated_by_danger?(danger_id) }

        if editable_comments.empty?
          previous_violations = {}
        else
          comment = editable_comments.first.body
          previous_violations = parse_comment(comment)
        end

        if previous_violations.empty? && (warnings + errors + messages + markdowns).empty?
          # Just remove the comment, if there"s nothing to say.
          delete_old_comments!(danger_id: danger_id)
        else
          body = generate_comment(warnings: warnings,
                                    errors: errors,
                                  messages: messages,
                                 markdowns: markdowns,
                       previous_violations: previous_violations,
                                 danger_id: danger_id,
                                  template: "gitlab")

          if editable_comments.empty?
            client.create_merge_request_comment(
              escaped_ci_slug, ci_source.pull_request_id, body
            )
          else
            original_id = editable_comments.first.id
            client.edit_merge_request_comment(
              escaped_ci_slug, ci_source.pull_request_id, original_id, body
            )
          end
        end
      end

      def delete_old_comments!(except: nil, danger_id: "danger")
        mr_comments.each do |comment|
          next unless comment.generated_by_danger?(danger_id)
          next if comment.id == except
          client.delete_merge_request_comment(
            escaped_ci_slug,
            ci_source.pull_request_id,
            comment.id
          )
        end
      end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        nil # TODO: Implement this
      end
    end
  end
end
