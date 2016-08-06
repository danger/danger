# coding: utf-8
require 'octokit'
require 'danger/helpers/comments_helper'

module Danger
  module RequestSources
    class GitHub < RequestSource
      include Danger::Helpers::CommentsHelper

      attr_accessor :pr_json, :issue_json, :support_tokenless_auth

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment
        self.support_tokenless_auth = false

        Octokit.auto_paginate = true
        @token = @environment['DANGER_GITHUB_API_TOKEN']
        if @environment['DANGER_GITHUB_API_HOST']
          Octokit.api_endpoint = @environment['DANGER_GITHUB_API_HOST']
        end
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host = @environment['DANGER_GITHUB_HOST'] || 'github.com'
      end

      def client
        raise 'No API token given, please provide one using `DANGER_GITHUB_API_TOKEN`' if !@token && !support_tokenless_auth
        @client ||= Octokit::Client.new(access_token: @token)
      end

      def pr_diff
        @pr_diff ||= client.pull_request(ci_source.repo_slug, ci_source.pull_request_id, accept: 'application/vnd.github.v3.diff')
      end

      def setup_danger_branches
        # we can use a github specific feature here:
        base_commit = self.pr_json[:base][:sha]
        head_commit = self.pr_json[:head][:sha]

        # Next, we want to ensure that we have a version of the current branch at a known location
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def fetch_details
        self.pr_json = client.pull_request(ci_source.repo_slug, ci_source.pull_request_id)
        fetch_issue_details(self.pr_json)
        self.ignored_violations = ignored_violations_from_pr(self.pr_json)
      end

      def ignored_violations_from_pr(pr_json)
        pr_body = pr_json[:body]
        return [] if pr_body.nil?
        pr_body.chomp.scan(/>\s*danger\s*:\s*ignore\s*"(.*)"/i).flatten
      end

      def fetch_issue_details(pr_json)
        href = pr_json[:_links][:issue][:href]
        self.issue_json = client.get(href)
      end

      # Sending data to GitHub
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: 'danger')
        comment_result = {}

        issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        editable_issues = issues.reject { |issue| issue[:body].include?("generated_by_#{danger_id}") == false }

        if editable_issues.empty?
          previous_violations = {}
        else
          comment = editable_issues.first[:body]
          previous_violations = parse_comment(comment)
        end

        if previous_violations.empty? && (warnings + errors + messages + markdowns).empty?
          # Just remove the comment, if there's nothing to say.
          delete_old_comments!(danger_id: danger_id)
        else

          cmp = proc do |a, b|
            next -1 unless a.file
            next 1 unless b.file

            next a.line <=> b.line if a.file == b.file
            next a.file <=> b.file
          end

          # Sort to group inline comments by file
          # We copy because we need to mutate this arrays for inlines
          comment_warnings = warnings.sort(&cmp)
          comment_errors = errors.sort(&cmp)
          comment_messages = messages.sort(&cmp)
          comment_markdowns = markdowns.sort(&cmp)

          submit_inline_comments!(warnings: comment_warnings,
                                    errors: comment_errors,
                                  messages: comment_messages,
                                 markdowns: comment_markdowns,
                       previous_violations: previous_violations,
                                 danger_id: danger_id)

          body = generate_comment(warnings: comment_warnings,
                                    errors: comment_errors,
                                  messages: comment_messages,
                                 markdowns: comment_markdowns,
                       previous_violations: previous_violations,
                                 danger_id: danger_id,
                                  template: 'github')

          if editable_issues.empty?
            comment_result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
          else
            original_id = editable_issues.first[:id]
            comment_result = client.update_comment(ci_source.repo_slug, original_id, body)
          end
        end

        # Now, set the pull request status.
        # Note: this can terminate the entire process.
        submit_pull_request_status!(warnings: warnings,
                                      errors: errors,
                                 details_url: comment_result['html_url'])
      end

      def submit_pull_request_status!(warnings: [], errors: [], details_url: [])
        status = (errors.count.zero? ? 'success' : 'failure')
        message = generate_description(warnings: warnings, errors: errors)

        latest_pr_commit_ref = self.pr_json[:head][:sha]

        if latest_pr_commit_ref.empty? || latest_pr_commit_ref.nil?
          raise "Couldn't find a commit to update its status".red
        end

        begin
          client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
            description: message,
            context: 'danger/danger',
            target_url: details_url
          })
        rescue
          # This usually means the user has no commit access to this repo
          # That's always the case for open source projects where you can only
          # use a read-only GitHub account
          if errors.count > 0
            # We need to fail the actual build here
            is_private = pr_json[:base][:repo][:private]
            if is_private
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)} and I don't have write access to the PR set a PR status.")
            else
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)}.")
            end
          else
            puts message
          end
        end
      end

      # Get rid of the previously posted comment, to only have the latest one
      def delete_old_comments!(except: nil, danger_id: 'danger')
        issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        issues.each do |issue|
          next unless issue[:body].include?("generated_by_#{danger_id}")
          next if issue[:id] == except
          client.delete_comment(ci_source.repo_slug, issue[:id])
        end
      end

      def submit_inline_comments!(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: [], danger_id: 'danger')
        filter = proc do |v|
          v.file && v.line
        end

        # Avoid doing any fetchs if there's no inline comments
        return if (warnings + errors + messages).select(&filter).empty?

        diff_lines = self.pr_diff.lines
        pr_comments = client.pull_request_comments(ci_source.repo_slug, ci_source.pull_request_id)
        danger_comments = pr_comments.select { |comment| comment[:body].include?("generated_by_#{danger_id}") }

        submit_inline_comments_for_kind!('warning', warnings, diff_lines, danger_comments, previous_violations[:warning], danger_id: danger_id)
        submit_inline_comments_for_kind!('no_entry_sign', errors, diff_lines, danger_comments, previous_violations[:error], danger_id: danger_id)
        submit_inline_comments_for_kind!('book', messages, diff_lines, danger_comments, previous_violations[:message], danger_id: danger_id)
        submit_inline_comments_for_kind!(nil, markdowns, diff_lines, danger_comments, [], danger_id: danger_id)

        # submit removes from the array all comments that are still in force
        # so we strike out all remaining ones
        danger_comments.each do |comment|
          violation = violations_from_table(comment[:body]).first
          next if violation.nil?

          # TODO: Check that this violation isn't now out of the diff (case of a force push)

          body = generate_inline_comment_body('white_check_mark', violation, danger_id: danger_id, resolved: true, template: "github")
          client.update_pull_request_comment(ci_source.repo_slug, comment[:id], body)
        end
      end

      def messages_are_equivalent(m1, m2)
        blob_regexp = %r{blob/[0-9a-z]+/}
        m1.file == m2.file && m1.line == m2.line &&
          m1.message.sub(blob_regexp, "") == m2.message.sub(blob_regexp, "")
      end

      def submit_inline_comments_for_kind!(emoji, messages, diff_lines, danger_comments, previous_violations, danger_id: "danger")
        head_ref = pr_json[:head][:sha]
        previous_violations ||= []
        is_markdown_content = emoji.nil?

        submit_inline = proc do |m|
          next false unless m.file && m.line

          position = find_position_in_diff diff_lines, m

          # Keep the change if it's line is not in the diff
          next false if position.nil?

          # Once we know we're gonna submit it, we format it
          if is_markdown_content
            body = generate_inline_markdown_body(m, danger_id: danger_id, template: "github")
          else
            m = process_markdown(m)
            body = generate_inline_comment_body(emoji, m, danger_id: danger_id, template: "github")
            # A comment might be in previous_violations because only now it's part of the unified diff
            # We remove from the array since it won't have a place in the table anymore
            previous_violations.reject! { |v| messages_are_equivalent(v, m) }
          end

          matching_comments = danger_comments.select do |comment_data|
            if comment_data[:path] == m.file && comment_data[:commit_id] == head_ref && comment_data[:position] == position
              # Parse it to avoid problems with strikethrough
              violation = violations_from_table(comment_data[:body]).first
              if violation
                messages_are_equivalent(violation, m)
              else
                comment_data[:body] == body
              end
            else
              false
            end
          end

          if matching_comments.empty?
            client.create_pull_request_comment(ci_source.repo_slug, ci_source.pull_request_id,
                                               body, head_ref, m.file, position)
          else
            # Remove the surviving comment so we don't strike it out
            danger_comments.reject! { |c| matching_comments.include? c }

            # Update the comment to remove the strikethrough if present
            comment = matching_comments.first
            client.update_pull_request_comment(ci_source.repo_slug, comment[:id], body)
          end

          # Remove this element from the array
          next true
        end

        messages.reject!(&submit_inline)
      end

      def find_position_in_diff(diff_lines, message)
        range_header_regexp = /@@ -([0-9]+),([0-9]+) \+(?<start>[0-9]+)(,(?<end>[0-9]+))? @@.*/
        file_header_regexp = %r{ a/.*}

        pattern = "+++ b/" + message.file + "\n"
        file_start = diff_lines.index(pattern)

        return nil if file_start.nil?

        position = -1
        file_line = nil

        diff_lines.drop(file_start).each do |line|
          match = line.match range_header_regexp

          # file_line is set once we find the hunk the line is in
          # we need to count how many lines in new file we have
          # so we do it one by one ignoring the deleted lines
          if !file_line.nil? && !line.start_with?('-')
            break if file_line == message.line
            file_line += 1
          end

          # We need to count how many diff lines are between us and
          # the line we're looking for
          position += 1

          next unless match

          # If we found the start of another file diff, we went too far
          break if line.match file_header_regexp

          range_start = match[:start].to_i
          if match[:end]
            range_end = match[:end].to_i + range_start
          else
            range_end = range_start
          end

          # We are past the line position, just abort
          break if message.line < range_start
          next unless message.line >= range_start && message.line <= range_end

          file_line = range_start
        end

        position unless file_line.nil?
      end

      def parse_message_from_row(row)
        message_regexp = %r{(<a href="https://github.com/#{ci_source.repo_slug}/blob/[0-9a-z]+/(?<file>[^#]+)#L(?<line>[0-9]+)">[^<]*</a> - )?(?<message>.*?)}im
        match = message_regexp.match(row)

        if match[:line]
          line = match[:line].to_i
        else
          line = nil
        end
        Violation.new(row, true, match[:file], line)
      end

      def markdown_link_to_message(message)
        "[#{message.file}#L#{message.line}](https://github.com/#{ci_source.repo_slug}/blob/#{pr_json[:head][:sha]}/#{message.file}#L#{message.line})"
      end

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        matched = self.issue_json[:repository_url].match(%r{repos\/(.*)\/})
        return matched[1] if matched && matched[1]
      rescue
        nil
      end

      # @return [Hash] with the information about the repo
      #   returns nil if the repo is not available
      def fetch_repository(organisation: nil, repository: nil)
        organisation ||= self.organisation
        repository ||= self.ci_source.repo_slug.split("/").last
        self.client.repo("#{organisation}/#{repository}")
      rescue Octokit::NotFound
        nil # repo doesn't exist
      end

      # @return [Hash] with the information about the repo.
      #   This will automatically detect if the repo is capitalised
      #   returns nil if there is no danger repo
      def fetch_danger_repo(organisation: nil)
        data = nil
        data ||= fetch_repository(organisation: organisation, repository: DANGER_REPO_NAME.downcase)
        data ||= fetch_repository(organisation: organisation, repository: DANGER_REPO_NAME.capitalize)
        data
      end

      # @return [Bool] is this repo the danger repo of the org?
      def danger_repo?(organisation: nil, repository: nil)
        repo = fetch_repository(organisation: organisation, repository: repository)
        repo[:name].casecmp(DANGER_REPO_NAME).zero? || repo[:parent] && repo[:parent][:full_name] == "danger/danger"
      rescue
        false
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, branch: 'master', path: nil)
        organisation ||= self.organisation
        "https://raw.githubusercontent.com/#{organisation}/#{repository}/#{branch}/#{path}"
      end
    end
  end
end
