# coding: utf-8
require "uri"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"
require "danger/request_sources/support/get_ignored_violation"

module Danger
  module RequestSources
    class GitLab < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :mr_json, :commits_json

      FIRST_VERSION_WITH_INLINE_COMMENTS = Gem::Version.new("10.8.0")

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
        @endpoint ||= @environment["DANGER_GITLAB_API_BASE_URL"] || @environment["CI_API_V4_URL"] || "https://gitlab.com/api/v4"
      end

      def host
        @host ||= @environment["DANGER_GITLAB_HOST"] || URI.parse(endpoint).host || "gitlab.com"
      end

      def base_commit
        @base_commit ||= self.mr_json.diff_refs.base_sha
      end

      def mr_comments
        @comments ||= begin
          if supports_inline_comments
            client.merge_request_discussions(ci_source.repo_slug, ci_source.pull_request_id)
              .auto_paginate
              .flat_map(&:notes)
              .map { |comment| Comment.from_gitlab_discussion(comment) }
          else
            client.merge_request_comments(ci_source.repo_slug, ci_source.pull_request_id, per_page: 100)
              .auto_paginate
              .map { |comment| Comment.from_gitlab(comment) }
          end
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

      def supports_inline_comments
        @supports_inline_comments ||= begin
          current_version = Gem::Version.new(client.version.version)

          current_version >= FIRST_VERSION_WITH_INLINE_COMMENTS
        end
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        if supports_inline_comments
          update_pull_request_with_inline_comments!(warnings: warnings, errors: errors, messages: messages, markdowns: markdowns, danger_id: danger_id, new_comment: new_comment, remove_previous_comments: remove_previous_comments)
        else
          update_pull_request_without_inline_comments!(warnings: warnings, errors: errors, messages: messages, markdowns: markdowns, danger_id: danger_id, new_comment: new_comment, remove_previous_comments: remove_previous_comments)
        end
      end

      def update_pull_request_with_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        editable_comments = mr_comments.select { |comment| comment.generated_by_danger?(danger_id) }

        should_create_new_comment = new_comment || editable_comments.empty? || remove_previous_comments

        if should_create_new_comment
          previous_violations = {}
        else
          comment = editable_comments.first.body
          previous_violations = parse_comment(comment)
        end

        regular_violations = regular_violations_group(
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns
        )

        inline_violations = inline_violations_group(
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns
        )

        rest_inline_violations = submit_inline_comments!({
          danger_id: danger_id,
          previous_violations: previous_violations
        }.merge(inline_violations))
      end

      def update_pull_request_without_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
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

          if editable_comments.empty? or should_create_new_comment
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

      def regular_violations_group(warnings: [], errors: [], messages: [], markdowns: [])
        {
          warnings: warnings.reject(&:inline?),
          errors: errors.reject(&:inline?),
          messages: messages.reject(&:inline?),
          markdowns: markdowns.reject(&:inline?)
        }
      end

      def inline_violations_group(warnings: [], errors: [], messages: [], markdowns: [])
        cmp = proc do |a, b|
          next -1 unless a.file && a.line
          next 1 unless b.file && b.line

          next a.line <=> b.line if a.file == b.file
          next a.file <=> b.file
        end

        # Sort to group inline comments by file
        {
          warnings: warnings.select(&:inline?).sort(&cmp),
          errors: errors.select(&:inline?).sort(&cmp),
          messages: messages.select(&:inline?).sort(&cmp),
          markdowns: markdowns.select(&:inline?).sort(&cmp)
        }
      end

      def submit_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: [], danger_id: "danger")
        # Avoid doing any fetchs if there's no inline comments
        return {} if (warnings + errors + messages + markdowns).select(&:inline?).empty?

        # diff_lines = self.mr_diff.lines
        comments = client.merge_request_discussions(ci_source.repo_slug, ci_source.pull_request_id)
          .auto_paginate
          .flat_map { |discussion| discussion.notes.map { |note| note.merge({"discussion_id" => discussion.id}) } }

        danger_comments = comments.select { |comment| Comment.from_gitlab_discussion(comment).generated_by_danger?(danger_id) }
        non_danger_comments = comments - danger_comments

        diff_lines = []

        warnings = submit_inline_comments_for_kind!(:warning, warnings, diff_lines, danger_comments, previous_violations["warning"], danger_id: danger_id)
        errors = submit_inline_comments_for_kind!(:error, errors, diff_lines, danger_comments, previous_violations["error"], danger_id: danger_id)
        messages = submit_inline_comments_for_kind!(:message, messages, diff_lines, danger_comments, previous_violations["message"], danger_id: danger_id)
        markdowns = submit_inline_comments_for_kind!(:markdown, markdowns, diff_lines, danger_comments, [], danger_id: danger_id)

        # submit removes from the array all comments that are still in force
        # so we strike out all remaining ones
        danger_comments.each do |comment|
          violation = violations_from_table(comment["body"]).first
          if !violation.nil? && violation.sticky
            body = generate_inline_comment_body("white_check_mark", violation, danger_id: danger_id, resolved: true, template: "gitlab")
            client.update_merge_request_discussion_note(ci_source.repo_slug, ci_source.pull_request_id, comment["discussion_id"], comment["id"], body)
          else
            # We remove non-sticky violations that have no replies
            # Since there's no direct concept of a reply in GH, we simply consider
            # the existance of non-danger comments in that line as replies
            replies = non_danger_comments.select do |potential|
              potential["path"] == comment["path"] &&
                potential["position"] == comment["position"] &&
                potential["commit_id"] == comment["commit_id"]
            end

            client.delete_merge_request_comment(ci_source.repo_slug, ci_source.pull_request_id, comment["id"]) if replies.empty?
          end
        end

        {
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns
        }
      end

      def submit_inline_comments_for_kind!(kind, messages, diff_lines, danger_comments, previous_violations, danger_id: "danger")
        previous_violations ||= []
        is_markdown_content = kind == :markdown
        emoji = { warning: "warning", error: "no_entry_sign", message: "book" }[kind]

        messages.reject do |m|
          next false unless m.file && m.line

          # position = find_position_in_diff diff_lines, m, kind

          # Keep the change if it's line is not in the diff and not in dismiss mode
          # next dismiss_out_of_range_messages_for(kind) if position.nil?

          # Once we know we're gonna submit it, we format it
          if is_markdown_content
            body = generate_inline_markdown_body(m, danger_id: danger_id, template: "gitlab")
          else
            # Hide the inline link behind a span
            m = process_markdown(m, true)
            body = generate_inline_comment_body(emoji, m, danger_id: danger_id, template: "gitlab")
            # A comment might be in previous_violations because only now it's part of the unified diff
            # We remove from the array since it won't have a place in the table anymore
            previous_violations.reject! { |v| messages_are_equivalent(v, m) }
          end

          matching_comments = danger_comments.select do |comment_data|
            if comment_data["path"] == m.file && comment_data["position"] == position
              # Parse it to avoid problems with strikethrough
              violation = violations_from_table(comment_data["body"]).first
              if violation
                messages_are_equivalent(violation, m)
              else
                blob_regexp = %r{blob/[0-9a-z]+/}
                comment_data["body"].sub(blob_regexp, "") == body.sub(blob_regexp, "")
              end
            else
              false
            end
          end

          if matching_comments.empty?
            params = {
              body: body,
              position: {
                position_type: 'text',
                new_path: m.file,
                new_line: m.line,
                base_sha: self.mr_json.diff_refs.base_sha,
                start_sha: self.mr_json.diff_refs.start_sha,
                head_sha: self.mr_json.diff_refs.head_sha
              }
            }
            client.create_merge_request_discussion(ci_source.repo_slug, ci_source.pull_request_id, params)
          else
            # Remove the surviving comment so we don't strike it out
            danger_comments.reject! { |c| matching_comments.include? c }

            # Update the comment to remove the strikethrough if present
            comment = matching_comments.first
            client.update_merge_request_comment(ci_source.repo_slug, comment["id"], body)
          end

          # Remove this element from the array
          next true
        end
      end

    end
  end
end
