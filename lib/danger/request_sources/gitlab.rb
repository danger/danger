# coding: utf-8

require "danger/helpers/comments_helper"
require "danger/helpers/comment"

require "danger/request_sources/support/get_ignored_violation"

module Danger
  module RequestSources
    class GitLab < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :mr_json, :commits_json

      def self.env_vars
        ["DANGER_GITLAB_API_TOKEN"]
      end

      def self.optional_env_vars
        ["DANGER_GITLAB_HOST", "DANGER_GITLAB_API_BASE_URL"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        @token = @environment["DANGER_GITLAB_API_TOKEN"]
      end

      def client
        token = @environment["DANGER_GITLAB_API_TOKEN"]
        raise "No API token given, please provide one using `DANGER_GITLAB_API_TOKEN`" unless token

        # The require happens inline so that it won't cause exceptions when just using the `danger` gem.
        require "gitlab"

        @client ||= Gitlab.client(endpoint: endpoint, private_token: token)
      rescue LoadError
        puts "The GitLab gem was not installed, you will need to change your Gem from `danger` to `danger-gitlab`.".red
        puts "\n - See https://github.com/danger/danger/blob/master/CHANGELOG.md#400"
        abort
      end

      def validates_as_ci?
        includes_port = self.host.include? ":"
        raise "Port number included in `DANGER_GITLAB_HOST`, this will fail with GitLab CI Runners" if includes_port

        super
      end

      def validates_as_api_source?
        @token && !@token.empty?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def endpoint
        @endpoint ||= @environment["DANGER_GITLAB_API_BASE_URL"] ||
                      "https://gitlab.com/api/v4"
      end

      def host
        @host ||= @environment["DANGER_GITLAB_HOST"] || "gitlab.com"
      end

      def base_commit
        @base_commit ||= self.mr_json.diff_refs.base_sha
      end

      def mr_comments
        @comments ||= begin
          client.merge_request_comments(ci_source.repo_slug, ci_source.pull_request_id, per_page: 100)
            .auto_paginate
            .map { |comment| Comment.from_gitlab(comment) }
        end
      end

      def mr_diff
        @mr_diff ||= begin
          client.merge_request_changes(ci_source.repo_slug, ci_source.pull_request_id)
            .changes.map { |change| change["diff"] }.join("\n")
        end
      end

      def setup_danger_branches
        base_branch = self.mr_json.source_branch
        head_branch = self.mr_json.target_branch
        head_commit = self.scm.head_commit

        raise "Are you running `danger local/pr` against the correct repository? Also this can happen if you run danger on MR without changes" if base_commit == head_commit

        # Next, we want to ensure that we have a version of the current branch at a known location
        scm.ensure_commitish_exists_on_branch! base_branch, base_commit
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        scm.ensure_commitish_exists_on_branch! head_branch, head_commit
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def fetch_details
        self.mr_json = client.merge_request(ci_source.repo_slug, self.ci_source.pull_request_id)
        self.ignored_violations = ignored_violations_from_pr
      end

      def ignored_violations_from_pr
        GetIgnoredViolation.new(self.mr_json.description).call
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        editable_comments = mr_comments.select { |comment| comment.generated_by_danger?(danger_id) }

        should_create_new_comment = new_comment || editable_comments.empty? || remove_previous_comments

        if should_create_new_comment
          previous_violations = {}
        else
          comment = editable_comments.first.body
          previous_violations = parse_comment(comment)
        end

        if (previous_violations.empty? && (warnings + errors + messages + markdowns).empty?) || remove_previous_comments
          # Just remove the comment, if there's nothing to say or --remove-previous-comments CLI was set.
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
              ci_source.repo_slug, ci_source.pull_request_id, body
            )
          else
            original_id = editable_comments.first.id
            client.edit_merge_request_comment(
              ci_source.repo_slug,
              ci_source.pull_request_id,
              original_id,
              { body: body }
            )
          end
        end
      end

      def delete_old_comments!(except: nil, danger_id: "danger")
        mr_comments.each do |comment|
          next unless comment.generated_by_danger?(danger_id)
          next if comment.id == except
          client.delete_merge_request_comment(
            ci_source.repo_slug,
            ci_source.pull_request_id,
            comment.id
          )
        end
      end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        nil # TODO: Implement this
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, branch: nil, path: nil)
        branch ||= 'master'

        "https://#{host}/#{organisation}/#{repository}/raw/#{branch}/#{path}"
      end
    end
  end
end
