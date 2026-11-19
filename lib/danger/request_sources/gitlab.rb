# frozen_string_literal: true

require "uri"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"
require "danger/request_sources/support/get_ignored_violation"
require "danger/output_registry/output_handler_registry"

module Danger
  module RequestSources
    class GitLab < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :mr_json, :commits_json, :dismiss_out_of_range_messages, :endpoint, :host

      FIRST_GITLAB_GEM_WITH_VERSION_CHECK = Gem::Version.new("4.6.0")
      FIRST_VERSION_WITH_INLINE_COMMENTS = Gem::Version.new("10.8.0")

      def self.env_vars
        ["DANGER_GITLAB_API_TOKEN"]
      end

      def self.optional_env_vars
        ["DANGER_GITLAB_HOST", "DANGER_GITLAB_API_BASE_URL"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.dismiss_out_of_range_messages = false
        @endpoint = environment["DANGER_GITLAB_API_BASE_URL"] || environment.fetch("CI_API_V4_URL", "https://gitlab.com/api/v4")
        @host = environment.fetch("DANGER_GITLAB_HOST", URI.parse(endpoint).host) || "gitlab.com"
        @token = environment["DANGER_GITLAB_API_TOKEN"]
      end

      def client
        raise "No API token given, please provide one using `DANGER_GITLAB_API_TOKEN`" unless @token

        # The require happens inline so that it won't cause exceptions when just using the `danger` gem.
        require "gitlab"

        @client ||= Gitlab.client(endpoint: endpoint, private_token: @token)
      rescue LoadError => e
        if e.path == "gitlab"
          puts "The GitLab gem was not installed, you will need to change your Gem from `danger` to `danger-gitlab`.".red
          puts "\n - See https://github.com/danger/danger/blob/master/CHANGELOG.md#400"
        else
          puts "Error: #{e}".red
        end
        abort
      end

      def validates_as_ci?
        includes_port = host.include? ":"
        raise "Port number included in `DANGER_GITLAB_HOST`, this will fail with GitLab CI Runners" if includes_port

        # We don't call super because in some cases the Git remote doesn't match the GitLab instance host.
        # In Danger::EnvironmentManager#initialize we still check that the request source is #validates_as_api_source?
        # so that should be sufficient to validate GitLab as request source.
        # See https://github.com/danger/danger/issues/1231 and https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10069.
        true
      end

      def validates_as_api_source?
        @token && !@token.empty?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def base_commit
        @base_commit ||= self.mr_json.diff_refs.base_sha
      end

      def mr_comments
        # @raw_comments contains what we got back from the server.
        # @comments contains Comment objects (that have less information)
        if supports_inline_comments
          @raw_comments = mr_discussions
            .auto_paginate
            .flat_map { |discussion| discussion.notes.map { |note| note.to_h.merge({ "discussion_id" => discussion.id }) } }
        else
          @raw_comments = client.merge_request_comments(ci_source.repo_slug, ci_source.pull_request_id, per_page: 100)
            .auto_paginate
        end
        @comments ||= @raw_comments
          .map { |comment| Comment.from_gitlab(comment) }
      end

      def mr_discussions
        @mr_discussions ||= client.merge_request_discussions(ci_source.repo_slug, ci_source.pull_request_id)
      end

      def mr_diff
        @mr_diff ||= begin
          diffs = mr_changes.changes.map do |change|
            diff = change["diff"]
            if diff.start_with?("--- a/")
              diff
            else
              "--- a/#{change['old_path']}\n+++ b/#{change['new_path']}\n#{diff}"
            end
          end
          diffs.join("\n")
        end
      end

      def mr_changed_paths
        @mr_changed_paths ||= mr_changes
          .changes.map { |change| change["new_path"] }

        @mr_changed_paths
      end

      def mr_changes
        @mr_changes ||= client.merge_request_changes(ci_source.repo_slug, ci_source.pull_request_id)
      end

      def mr_closes_issues
        @mr_closes_issues ||= client.merge_request_closes_issues(ci_source.repo_slug, ci_source.pull_request_id)
      end

      def setup_danger_branches
        # we can use a GitLab specific feature here:
        base_branch = self.mr_json.source_branch
        base_commit = self.mr_json.diff_refs.base_sha
        head_branch = self.mr_json.target_branch
        head_commit = self.mr_json.diff_refs.head_sha

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

      def supports_inline_comments
        # If we can't check GitLab's version, we assume we don't support inline comments
        @supports_inline_comments ||= if Gem.loaded_specs["gitlab"].version < FIRST_GITLAB_GEM_WITH_VERSION_CHECK
                                        false
                                      else
                                        current_version = Gem::Version.new(client.version.version)

                                        current_version >= FIRST_VERSION_WITH_INLINE_COMMENTS
                                      end
      end

      # Sending data to GitLab
      #
      # Delegates to the OutputHandlerRegistry which executes the appropriate
      # handlers for GitLab (comment, inline comments).
      #
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        OutputRegistry::OutputHandlerRegistry.execute_for_request_source(
          self,
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns,
          danger_id: danger_id,
          new_comment: new_comment,
          remove_previous_comments: remove_previous_comments
        )
      end

      def delete_old_comments!(except: nil, danger_id: "danger")
        @raw_comments.each do |raw_comment|
          comment = Comment.from_gitlab(raw_comment)
          next unless comment.generated_by_danger?(danger_id)
          next if comment.id == except
          next unless raw_comment.kind_of?(Hash) && raw_comment["position"].nil?

          begin
            client.delete_merge_request_comment(
              ci_source.repo_slug,
              ci_source.pull_request_id,
              comment.id
            )
          rescue StandardError
          end
        end
      end

      def markdown_link_to_message(message, _)
        "#{message.file}#L#{message.line}: "
      end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        nil # TODO: Implement this
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, ref: nil, branch: nil, path: nil)
        ref ||= branch || "master"
        # According to GitLab Repositories API docs path and id(slug) should be encoded.
        path = URI.encode_www_form_component(path)
        repository = URI.encode_www_form_component(repository)
        "#{endpoint}/projects/#{repository}/repository/files/#{path}/raw?ref=#{ref}&private_token=#{@token}"
      end

      def is_out_of_range(changes, message)
        change = changes.find { |c| c["new_path"] == message.file }
        # If there is no changes or rename only or deleted, return out of range.
        return true if change.nil? || change["diff"].empty? || change["deleted_file"]

        # If new file then return in range
        return false if change["new_file"]

        addition_lines = generate_addition_lines(change["diff"])
        return false if addition_lines.include?(message.line.to_i)

        return true
      end

      def generate_addition_lines(diff)
        range_header_regexp = /@@ -(?<old>[0-9]+)(,([0-9]+))? \+(?<new>[0-9]+)(,([0-9]+))? @@.*/
        addition_lines = []
        line_number = 0
        diff.each_line do |line|
          if line.match range_header_regexp
            line = line.split("+").last
            line = line.split(" ").first
            range_string = line.split(",")
            line_number = range_string[0].to_i - 1
          elsif line.start_with?("+")
            addition_lines.push(line_number)
          elsif line.start_with?("-")
            line_number -= 1
          end
          line_number += 1
        end
        addition_lines
      end
    end
  end
end
