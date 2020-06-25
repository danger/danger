# coding: utf-8

# rubocop:disable Metrics/ClassLength

require "octokit"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"
require "danger/request_sources/github/github_review"
require "danger/request_sources/github/github_review_unsupported"
require "danger/request_sources/support/get_ignored_violation"

module Danger
  module RequestSources
    class GitHub < RequestSource
      include Danger::Helpers::CommentsHelper

      attr_accessor :pr_json, :issue_json, :support_tokenless_auth, :dismiss_out_of_range_messages

      def self.env_vars
        ["DANGER_GITHUB_API_TOKEN"]
      end

      def self.optional_env_vars
        ["DANGER_GITHUB_HOST", "DANGER_GITHUB_API_BASE_URL", "DANGER_OCTOKIT_VERIFY_SSL"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment
        self.support_tokenless_auth = false
        self.dismiss_out_of_range_messages = false

        @token = @environment["DANGER_GITHUB_API_TOKEN"]
      end

      def get_pr_from_branch(repo_name, branch_name, owner)
        prs = client.pull_requests(repo_name, head: "#{owner}:#{branch_name}")
        unless prs.empty?
          prs.first.number
        end
      end

      def validates_as_ci?
        true
      end

      def validates_as_api_source?
        (@token && !@token.empty?) || self.environment["DANGER_USE_LOCAL_GIT"]
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host = @environment["DANGER_GITHUB_HOST"] || "github.com"
      end

      def verify_ssl
        @environment["DANGER_OCTOKIT_VERIFY_SSL"] == "false" ? false : true
      end

      # `DANGER_GITHUB_API_HOST` is the old name kept for legacy reasons and
      # backwards compatibility. `DANGER_GITHUB_API_BASE_URL` is the new
      # correctly named variable.
      def api_url
        @environment.fetch("DANGER_GITHUB_API_HOST") do
          @environment.fetch("DANGER_GITHUB_API_BASE_URL") do
            "https://api.github.com/".freeze
          end
        end
      end

      def client
        raise "No API token given, please provide one using `DANGER_GITHUB_API_TOKEN`" if !@token && !support_tokenless_auth
        @client ||= begin
          Octokit.configure do |config|
            config.connection_options[:ssl] = { verify: verify_ssl }
          end
          Octokit::Client.new(access_token: @token, auto_paginate: true, api_endpoint: api_url)
        end
      end

      def pr_diff
        @pr_diff ||= client.pull_request(ci_source.repo_slug, ci_source.pull_request_id, accept: "application/vnd.github.v3.diff")
      end

      def review
        return @review unless @review.nil?
        begin
          @review = client.pull_request_reviews(ci_source.repo_slug, ci_source.pull_request_id)
            .map { |review_json| Danger::RequestSources::GitHubSource::Review.new(client, ci_source, review_json) }
            .select(&:generated_by_danger?)
            .last
          @review ||= Danger::RequestSources::GitHubSource::Review.new(client, ci_source)
          @review
        rescue Octokit::NotFound
          @review = Danger::RequestSources::GitHubSource::ReviewUnsupported.new
          @review
        end
      end

      def setup_danger_branches
        # we can use a github specific feature here:
        base_branch = self.pr_json["base"]["ref"]
        base_commit = self.pr_json["base"]["sha"]
        head_branch = self.pr_json["head"]["ref"]
        head_commit = self.pr_json["head"]["sha"]

        # Next, we want to ensure that we have a version of the current branch at a known location
        scm.ensure_commitish_exists_on_branch! base_branch, base_commit
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        scm.ensure_commitish_exists_on_branch! head_branch, head_commit
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def fetch_details
        self.pr_json = client.pull_request(ci_source.repo_slug, ci_source.pull_request_id)
        if self.pr_json["message"] == "Moved Permanently"
          raise "Repo moved or renamed, make sure to update the git remote".red
        end

        fetch_issue_details(self.pr_json)
        self.ignored_violations = ignored_violations_from_pr
      end

      def ignored_violations_from_pr
        GetIgnoredViolation.new(self.pr_json["body"]).call
      end

      def fetch_issue_details(pr_json)
        href = pr_json["_links"]["issue"]["href"]
        self.issue_json = client.get(href)
      end

      def issue_comments
        @comments ||= begin
          client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
            .map { |comment| Comment.from_github(comment) }
        end
      end

      # Sending data to GitHub
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        comment_result = {}
        editable_comments = issue_comments.select { |comment| comment.generated_by_danger?(danger_id) }
        last_comment = editable_comments.last
        should_create_new_comment = new_comment || last_comment.nil? || remove_previous_comments

        previous_violations =
          if should_create_new_comment
            {}
          else
            parse_comment(last_comment.body)
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
        }.merge(**inline_violations))

        main_violations = merge_violations(
          regular_violations, rest_inline_violations
        )

        main_violations_sum = main_violations.values.inject(:+)

        if (previous_violations.empty? && main_violations_sum.empty?) || remove_previous_comments
          # Just remove the comment, if there's nothing to say or --remove-previous-comments CLI was set.
          delete_old_comments!(danger_id: danger_id)
        end

        # If there are still violations to show
        if main_violations_sum.any?
          body = generate_comment({
            template: "github",
            danger_id: danger_id,
            previous_violations: previous_violations
          }.merge(**main_violations))

          comment_result =
            if should_create_new_comment
              client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
            else
              client.update_comment(ci_source.repo_slug, last_comment.id, body)
            end
        end

        # Now, set the pull request status.
        # Note: this can terminate the entire process.
        submit_pull_request_status!(
          warnings: warnings,
          errors: errors,
          details_url: comment_result["html_url"],
          danger_id: danger_id
        )
      end

      def submit_pull_request_status!(warnings: [], errors: [], details_url: [], danger_id: "danger")
        status = (errors.count.zero? ? "success" : "failure")
        message = generate_description(warnings: warnings, errors: errors)
        latest_pr_commit_ref = self.pr_json["head"]["sha"]

        if latest_pr_commit_ref.empty? || latest_pr_commit_ref.nil?
          raise "Couldn't find a commit to update its status".red
        end

        begin
          client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
            description: message,
            context: "danger/#{danger_id}",
            target_url: details_url
          })
        rescue
          # This usually means the user has no commit access to this repo
          # That's always the case for open source projects where you can only
          # use a read-only GitHub account
          if errors.count > 0
            # We need to fail the actual build here
            is_private = pr_json["base"]["repo"]["private"]
            if is_private
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)} and I don't have write access to the PR to set a PR status.")
            else
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)}.")
            end
          else
            puts message
            puts "\nDanger does not have write access to the PR to set a PR status.".yellow
          end
        end
      end

      # Get rid of the previously posted comment, to only have the latest one
      def delete_old_comments!(except: nil, danger_id: "danger")
        issue_comments.each do |comment|
          next unless comment.generated_by_danger?(danger_id)
          next if comment.id == except
          client.delete_comment(ci_source.repo_slug, comment.id)
        end
      end

      def submit_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: [], danger_id: "danger")
        # Avoid doing any fetchs if there's no inline comments
        return {} if (warnings + errors + messages + markdowns).select(&:inline?).empty?

        diff_lines = self.pr_diff.lines
        pr_comments = client.pull_request_comments(ci_source.repo_slug, ci_source.pull_request_id)
        danger_comments = pr_comments.select { |comment| Comment.from_github(comment).generated_by_danger?(danger_id) }
        non_danger_comments = pr_comments - danger_comments

        warnings = submit_inline_comments_for_kind!(:warning, warnings, diff_lines, danger_comments, previous_violations["warning"], danger_id: danger_id)
        errors = submit_inline_comments_for_kind!(:error, errors, diff_lines, danger_comments, previous_violations["error"], danger_id: danger_id)
        messages = submit_inline_comments_for_kind!(:message, messages, diff_lines, danger_comments, previous_violations["message"], danger_id: danger_id)
        markdowns = submit_inline_comments_for_kind!(:markdown, markdowns, diff_lines, danger_comments, [], danger_id: danger_id)

        # submit removes from the array all comments that are still in force
        # so we strike out all remaining ones
        danger_comments.each do |comment|
          violation = violations_from_table(comment["body"]).first
          if !violation.nil? && violation.sticky
            body = generate_inline_comment_body("white_check_mark", violation, danger_id: danger_id, resolved: true, template: "github")
            client.update_pull_request_comment(ci_source.repo_slug, comment["id"], body)
          else
            # We remove non-sticky violations that have no replies
            # Since there's no direct concept of a reply in GH, we simply consider
            # the existence of non-danger comments in that line as replies
            replies = non_danger_comments.select do |potential|
              potential["path"] == comment["path"] &&
                potential["position"] == comment["position"] &&
                potential["commit_id"] == comment["commit_id"]
            end

            client.delete_pull_request_comment(ci_source.repo_slug, comment["id"]) if replies.empty?
          end
        end

        {
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns
        }
      end

      def messages_are_equivalent(m1, m2)
        blob_regexp = %r{blob/[0-9a-z]+/}
        m1.file == m2.file && m1.line == m2.line &&
          m1.message.sub(blob_regexp, "") == m2.message.sub(blob_regexp, "")
      end

      def submit_inline_comments_for_kind!(kind, messages, diff_lines, danger_comments, previous_violations, danger_id: "danger")
        head_ref = pr_json["head"]["sha"]
        previous_violations ||= []
        is_markdown_content = kind == :markdown
        emoji = { warning: "warning", error: "no_entry_sign", message: "book" }[kind]

        messages.reject do |m|
          next false unless m.file && m.line

          position = find_position_in_diff diff_lines, m, kind

          # Keep the change if it's line is not in the diff and not in dismiss mode
          next dismiss_out_of_range_messages_for(kind) if position.nil?

          # Once we know we're gonna submit it, we format it
          if is_markdown_content
            body = generate_inline_markdown_body(m, danger_id: danger_id, template: "github")
          else
            # Hide the inline link behind a span
            m = process_markdown(m, true)
            body = generate_inline_comment_body(emoji, m, danger_id: danger_id, template: "github")
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
            begin
              client.create_pull_request_comment(ci_source.repo_slug, ci_source.pull_request_id,
                                                 body, head_ref, m.file, position)
            rescue Octokit::UnprocessableEntity => e
              # Show more detail for UnprocessableEntity error
              message = [e, "body: #{body}", "head_ref: #{head_ref}", "filename: #{m.file}", "position: #{position}"].join("\n")
              puts message

              # Not reject because this comment has not completed
              next false
            end
          else
            # Remove the surviving comment so we don't strike it out
            danger_comments.reject! { |c| matching_comments.include? c }

            # Update the comment to remove the strikethrough if present
            comment = matching_comments.first
            client.update_pull_request_comment(ci_source.repo_slug, comment["id"], body)
          end

          # Remove this element from the array
          next true
        end
      end

      def find_position_in_diff(diff_lines, message, kind)
        range_header_regexp = /@@ -([0-9]+)(,([0-9]+))? \+(?<start>[0-9]+)(,(?<end>[0-9]+))? @@.*/
        file_header_regexp = %r{^diff --git a/.*}

        pattern = "+++ b/" + message.file + "\n"
        file_start = diff_lines.index(pattern)

        # Files containing spaces sometimes have a trailing tab
        if file_start.nil?
          pattern = "+++ b/" + message.file + "\t\n"
          file_start = diff_lines.index(pattern)
        end

        return nil if file_start.nil?

        position = -1
        file_line = nil

        diff_lines.drop(file_start).each do |line|
          # If the line has `No newline` annotation, position need increment
          if line.eql?("\\ No newline at end of file\n")
            position += 1
            next
          end
          # If we found the start of another file diff, we went too far
          break if line.match file_header_regexp

          match = line.match range_header_regexp

          # file_line is set once we find the hunk the line is in
          # we need to count how many lines in new file we have
          # so we do it one by one ignoring the deleted lines
          if !file_line.nil? && !line.start_with?("-")
            if file_line == message.line
              file_line = nil if dismiss_out_of_range_messages_for(kind) && !line.start_with?("+")
              break
            end
            file_line += 1
          end

          # We need to count how many diff lines are between us and
          # the line we're looking for
          position += 1

          next unless match

          range_start = match[:start].to_i
          if match[:end]
            range_end = match[:end].to_i + range_start
          else
            range_end = range_start
          end

          # We are past the line position, just abort
          break if message.line.to_i < range_start
          next unless message.line.to_i >= range_start && message.line.to_i < range_end

          file_line = range_start
        end

        position unless file_line.nil?
      end

      # See the tests for examples of data coming in looks like
      def parse_message_from_row(row)
        message_regexp = %r{(<(a |span data-)href="https://#{host}/#{ci_source.repo_slug}/blob/[0-9a-z]+/(?<file>[^#]+)#L(?<line>[0-9]+)"(>[^<]*</a> - |/>))?(?<message>.*?)}im
        match = message_regexp.match(row)

        if match[:line]
          line = match[:line].to_i
        else
          line = nil
        end
        Violation.new(row, true, match[:file], line)
      end

      def markdown_link_to_message(message, hide_link)
        url = "https://#{host}/#{ci_source.repo_slug}/blob/#{pr_json['head']['sha']}/#{message.file}#L#{message.line}"

        if hide_link
          "<span data-href=\"#{url}\"/>"
        else
          "[#{message.file}#L#{message.line}](#{url}) - "
        end
      end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        matched = self.issue_json["repository_url"].match(%r{repos\/(.*)\/})
        return matched[1] if matched && matched[1]
      rescue
        nil
      end

      def dismiss_out_of_range_messages_for(kind)
        if self.dismiss_out_of_range_messages.kind_of?(Hash) && self.dismiss_out_of_range_messages[kind]
          self.dismiss_out_of_range_messages[kind]
        elsif self.dismiss_out_of_range_messages == true
          self.dismiss_out_of_range_messages
        else
          false
        end
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, branch: nil, path: nil)
        organisation ||= self.organisation

        begin
          # Retrieve the download URL (default branch on nil param)
          contents = client.contents("#{organisation}/#{repository}", path: path, ref: branch)
          @download_url = contents["download_url"]
        rescue Octokit::ClientError
          # Fallback to github.com
          branch ||= "master"
          @download_url = "https://raw.githubusercontent.com/#{organisation}/#{repository}/#{branch}/#{path}"
        end
      end

      private

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

      def merge_violations(*violation_groups)
        violation_groups.inject({}) do |accumulator, group|
          accumulator.merge(group) { |_, old, fresh| old + fresh }
        end
      end
    end
  end
end
