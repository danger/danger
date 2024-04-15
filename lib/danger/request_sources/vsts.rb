require "danger/helpers/comments_helper"
require "danger/request_sources/vsts_api"

module Danger
  module RequestSources
    class VSTS < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def self.env_vars
        [
          "DANGER_VSTS_API_TOKEN",
          "DANGER_VSTS_HOST"
        ]
      end

      def self.optional_env_vars
        [
          "DANGER_VSTS_API_VERSION"
        ]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source

        @is_vsts_ci = environment.key? "DANGER_VSTS_HOST"

        @api = VSTSAPI.new(ci_source.repo_slug, ci_source.pull_request_id, environment)
      end

      def validates_as_ci?
        @is_vsts_ci
      end

      def validates_as_api_source?
        @api.credentials_given?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def client
        @api
      end

      def host
        @host ||= @api.host
      end

      def fetch_details
        self.pr_json = @api.fetch_pr_json
      end

      def setup_danger_branches
        base_branch = self.pr_json[:targetRefName].sub("refs/heads/", "")
        base_commit = self.pr_json[:lastMergeTargetCommit][:commitId]
        head_branch = self.pr_json[:sourceRefName].sub("refs/heads/", "")
        head_commit = self.pr_json[:lastMergeSourceCommit][:commitId]

        # Next, we want to ensure that we have a version of the current branch at a known location
        scm.ensure_commitish_exists_on_branch! base_branch, base_commit
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        scm.ensure_commitish_exists_on_branch! head_branch, head_commit
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def organisation
        nil
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        unless @api.supports_comments?
          return
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

        rest_inline_violations = submit_inline_comments!(**{
          danger_id: danger_id,
          previous_violations: {}
        }.merge(inline_violations))

        main_violations = merge_violations(
          regular_violations, rest_inline_violations
        )

        comment = generate_description(warnings: main_violations[:warnings], errors: main_violations[:errors])
        comment += "\n\n"
        comment += generate_comment(**{
          previous_violations: {},
          danger_id: danger_id,
          template: "vsts"
        }.merge(main_violations))
        if new_comment || remove_previous_comments
          post_new_comment(comment)
        else
          update_old_comment(comment, danger_id: danger_id)
        end
      end

      def post_new_comment(comment)
        @api.post_comment(comment)
      end

      def update_old_comment(new_comment, danger_id: "danger")
        comment_updated = false
        @api.fetch_last_comments.each do |c|
          thread_id = c[:id]
          comment = c[:comments].first
          comment_id = comment[:id]
          comment_content = comment[:content].nil? ? "" : comment[:content]
          # Skip the comment if it wasn't posted by danger
          next unless comment_content.include?("generated_by_#{danger_id}")
          # Skip the comment if it's an inline comment
          next unless c[:threadContext].nil?

          # Updated the danger posted comment
          @api.update_comment(thread_id, comment_id, new_comment)
          comment_updated = true
        end
        # If no comment was updated, post a new one
        post_new_comment(new_comment) unless comment_updated
      end

      def submit_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: [], danger_id: "danger")
        # Avoid doing any fetches if there's no inline comments
        return {} if (warnings + errors + messages + markdowns).select(&:inline?).empty?

        pr_threads = @api.fetch_last_comments
        danger_threads = pr_threads.select do |thread|
          comment = thread[:comments].first
          comment_content = comment[:content].nil? ? "" : comment[:content]

          next comment_content.include?("generated_by_#{danger_id}")
        end
        non_danger_threads = pr_threads - danger_threads

        warnings = submit_inline_comments_for_kind!(:warning, warnings, danger_threads, previous_violations["warning"], danger_id: danger_id)
        errors = submit_inline_comments_for_kind!(:error, errors, danger_threads, previous_violations["error"], danger_id: danger_id)
        messages = submit_inline_comments_for_kind!(:message, messages, danger_threads, previous_violations["message"], danger_id: danger_id)
        markdowns = submit_inline_comments_for_kind!(:markdown, markdowns, danger_threads, [], danger_id: danger_id)

        # submit removes from the array all comments that are still in force
        # so we strike out all remaining ones
        danger_threads.each do |thread|
          violation = violations_from_table(thread[:comments].first[:content]).first
          if !violation.nil? && violation.sticky
            body = generate_inline_comment_body("white_check_mark", violation, danger_id: danger_id, resolved: true, template: "github")
            @api.update_comment(thread[:id], thread[:comments].first[:id], body)
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

      def submit_inline_comments_for_kind!(kind, messages, danger_threads, previous_violations, danger_id: "danger")
        previous_violations ||= []
        is_markdown_content = kind == :markdown
        emoji = { warning: "warning", error: "no_entry_sign", message: "book" }[kind]

        messages.reject do |m|
          next false unless m.file && m.line

          # Once we know we're gonna submit it, we format it
          if is_markdown_content
            body = generate_inline_markdown_body(m, danger_id: danger_id, template: "vsts")
          else
            # Hide the inline link behind a span
            m.message = m.message.gsub("\n", "<br />")
            m = process_markdown(m, true)
            body = generate_inline_comment_body(emoji, m, danger_id: danger_id, template: "vsts")
            # A comment might be in previous_violations because only now it's part of the unified diff
            # We remove from the array since it won't have a place in the table anymore
            previous_violations.reject! { |v| messages_are_equivalent(v, m) }
          end

          matching_threads = danger_threads.select do |comment_data|
            if comment_data.key?(:threadContext) && !comment_data[:threadContext].nil? &&
               comment_data[:threadContext][:filePath] == m.file &&
               comment_data[:threadContext].key?(:rightFileStart) &&
               comment_data[:threadContext][:rightFileStart][:line] == m.line
              # Parse it to avoid problems with strikethrough
              violation = violations_from_table(comment_data[:comments].first[:content]).first
              if violation
                messages_are_equivalent(violation, m)
              else
                blob_regexp = %r{blob/[0-9a-z]+/}
                comment_data[:comments].first[:content].sub(blob_regexp, "") == body.sub(blob_regexp, "")
              end
            else
              false
            end
          end

          if matching_threads.empty?
            @api.post_inline_comment(body, m.file, m.line)

            # Not reject because this comment has not completed
            next false
          else
            # Remove the surviving comment so we don't strike it out
            danger_threads.reject! { |c| matching_threads.include? c }

            # Update the comment to remove the strikethrough if present
            thread = matching_threads.first
            @api.update_comment(thread[:id], thread[:comments].first[:id], body)
          end

          # Remove this element from the array
          next true
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
