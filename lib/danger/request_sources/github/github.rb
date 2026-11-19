# frozen_string_literal: true

require "octokit"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"
require "danger/request_sources/github/github_review"
require "danger/request_sources/github/github_review_unsupported"
require "danger/request_sources/support/get_ignored_violation"
require "danger/output_registry/output_handler_registry"

module Danger
  module RequestSources
    class GitHub < RequestSource
      include Danger::Helpers::CommentsHelper

      DiffLineReference = Struct.new(:file, :line)

      attr_accessor :pr_json, :issue_json, :use_local_git, :support_tokenless_auth, :dismiss_out_of_range_messages, :host, :api_url, :verify_ssl

      def self.env_vars
        ["DANGER_GITHUB_API_TOKEN", "DANGER_GITHUB_BEARER_TOKEN"]
      end

      def self.optional_env_vars
        ["DANGER_GITHUB_HOST", "DANGER_GITHUB_API_BASE_URL", "DANGER_OCTOKIT_VERIFY_SSL"]
      end

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.use_local_git = environment["DANGER_USE_LOCAL_GIT"]
        self.support_tokenless_auth = false
        self.dismiss_out_of_range_messages = false
        self.host = environment.fetch("DANGER_GITHUB_HOST", "github.com")
        # `DANGER_GITHUB_API_HOST` is the old name kept for legacy reasons and
        # backwards compatibility. `DANGER_GITHUB_API_BASE_URL` is the new
        # correctly named variable.
        self.api_url = environment.fetch("DANGER_GITHUB_API_HOST") do
          environment.fetch("DANGER_GITHUB_API_BASE_URL", "https://api.github.com/")
        end
        self.verify_ssl = environment["DANGER_OCTOKIT_VERIFY_SSL"] != "false"

        @access_token = environment["DANGER_GITHUB_API_TOKEN"]
        @bearer_token = environment["DANGER_GITHUB_BEARER_TOKEN"]
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
        valid_bearer_token? || valid_access_token? || use_local_git
      end

      def scm
        @scm ||= GitRepo.new
      end

      def client
        raise "No API token given, please provide one using `DANGER_GITHUB_API_TOKEN` or `DANGER_GITHUB_BEARER_TOKEN`" if !valid_access_token? && !valid_bearer_token? && !support_tokenless_auth

        @client ||= begin
          Octokit.configure do |config|
            config.connection_options[:ssl] = { verify: verify_ssl }
          end
          if valid_bearer_token?
            Octokit::Client.new(bearer_token: @bearer_token, auto_paginate: true, api_endpoint: api_url)
          elsif valid_access_token?
            Octokit::Client.new(access_token: @access_token, auto_paginate: true, api_endpoint: api_url)
          end
        end
      end

      def pr_diff
        # This is a hack to get the file patch into a format that parse-diff accepts
        # as the GitHub API for listing pull request files is missing file names in the patch.
        prefixed_patch = lambda do |file:|
          <<~PATCH
          diff --git a/#{file['filename']} b/#{file['filename']}
          --- a/#{file['filename']}
          +++ b/#{file['filename']}
          #{file['patch']}
          PATCH
        end

        files = client.pull_request_files(
          ci_source.repo_slug,
          ci_source.pull_request_id,
          accept: "application/vnd.github.v3.diff"
        )

        @pr_diff ||= files.map { |file| prefixed_patch.call(file: file) }.join("\n")
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
        @comments ||= client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
          .map { |comment| Comment.from_github(comment) }
      end

      # Sending data to GitHub
      #
      # Delegates to the OutputHandlerRegistry which executes the appropriate
      # handlers for GitHub (comment, inline comments, commit status).
      #
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false, remove_previous_comments: false)
        shared_state = OutputRegistry::OutputHandlerRegistry.execute_for_request_source(
          self,
          warnings: warnings,
          errors: errors,
          messages: messages,
          markdowns: markdowns,
          danger_id: danger_id,
          new_comment: new_comment,
          remove_previous_comments: remove_previous_comments
        )

        # NOTE: this can terminate the entire process.
        submit_pull_request_status!(
          warnings: warnings,
          errors: errors,
          details_url: shared_state[:comment_url],
          danger_id: danger_id
        )
      end

      def submit_pull_request_status!(warnings: [], errors: [], details_url: [], danger_id: "danger")
        status = (errors.count.zero? ? "success" : "failure")
        message = generate_description(warnings: warnings, errors: errors)
        latest_pr_commit_ref = ci_source.commit_sha || self.pr_json["head"]["sha"]

        if latest_pr_commit_ref.empty? || latest_pr_commit_ref.nil?
          raise "Couldn't find a commit to update its status".red
        end

        begin
          client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
            description: message,
            context: "danger/#{danger_id}",
            target_url: details_url
          })
        rescue StandardError
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

      def messages_are_equivalent(m1, m2)
        blob_regexp = %r{blob/[0-9a-z]+/}
        m1.file == m2.file && m1.line == m2.line &&
          m1.message.sub(blob_regexp, "") == m2.message.sub(blob_regexp, "")
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
        matched = self.issue_json["repository_url"].match(%r{repos/(.*)/})
        return matched[1] if matched && matched[1]
      rescue StandardError
        nil
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, ref: nil, branch: nil, path: nil)
        organisation ||= self.organisation
        ref ||= branch

        begin
          # Retrieve the download URL (default ref on nil param)
          contents = client.contents("#{organisation}/#{repository}", path: path, ref: ref)
          @download_url = contents["download_url"]
        rescue Octokit::ClientError
          # Fallback to github.com
          ref ||= "master"
          @download_url = "https://raw.githubusercontent.com/#{organisation}/#{repository}/#{ref}/#{path}"
        end
      end

      private

      def valid_access_token?
        @access_token && !@access_token.empty?
      end

      def valid_bearer_token?
        @bearer_token && !@bearer_token.empty?
      end
    end
  end
end
