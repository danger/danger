# coding: utf-8
require "octokit"
require "danger/helpers/comments_helper"

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
        @token = @environment["DANGER_GITHUB_API_TOKEN"]
        if @environment["DANGER_GITHUB_API_HOST"]
          Octokit.api_endpoint = @environment["DANGER_GITHUB_API_HOST"]
        end
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host = @environment["DANGER_GITHUB_HOST"] || "github.com"
      end

      def client
        raise "No API token given, please provide one using `DANGER_GITHUB_API_TOKEN`" if !@token && !support_tokenless_auth
        @client ||= Octokit::Client.new(access_token: @token)
      end

      def pr_diff
        @pr_diff ||= client.pull_request(ci_source.repo_slug, ci_source.pull_request_id, accept: "application/vnd.github.v3.diff")
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
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger")
        comment_result = {}

        comments = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        editable_comments = comments.select { |comment| danger_comment?(comment, danger_id) }

        if editable_comments.empty?
          previous_violations = {}
        else
          comment = editable_comments.first[:body]
          previous_violations = parse_comment(comment)
        end

        if previous_violations.empty? && (warnings + errors + messages + markdowns).empty?
          # Just remove the comment, if there's nothing to say.
          delete_old_comments!(danger_id: danger_id)
        else
          body = generate_comment(warnings: warnings,
                                    errors: errors,
                                  messages: messages,
                                 markdowns: markdowns,
                       previous_violations: previous_violations,
                                 danger_id: danger_id,
                                  template: "github")

          if editable_comments.empty?
            comment_result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
          else
            original_id = editable_comments.first[:id]
            comment_result = client.update_comment(ci_source.repo_slug, original_id, body)
          end
        end

        # Now, set the pull request status.
        # Note: this can terminate the entire process.
        submit_pull_request_status!(warnings: warnings,
                                      errors: errors,
                                 details_url: comment_result["html_url"])
      end

      def submit_pull_request_status!(warnings: [], errors: [], details_url: [])
        status = (errors.count.zero? ? "success" : "failure")
        message = generate_description(warnings: warnings, errors: errors)

        latest_pr_commit_ref = self.pr_json[:head][:sha]

        if latest_pr_commit_ref.empty? || latest_pr_commit_ref.nil?
          raise "Couldn't find a commit to update its status".red
        end

        begin
          client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
            description: message,
            context: "danger/danger",
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
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)} and I don't have write access to the PR to set a PR status.")
            else
              abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)}.")
            end
          else
            puts message
          end
        end
      end

      # Get rid of the previously posted comment, to only have the latest one
      def delete_old_comments!(except: nil, danger_id: "danger")
        comments = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        comments.each do |comment|
          next unless danger_comment?(comment, danger_id)
          next if comment[:id] == except
          client.delete_comment(ci_source.repo_slug, comment[:id])
        end
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
      def file_url(organisation: nil, repository: nil, branch: "master", path: nil)
        organisation ||= self.organisation
        "https://raw.githubusercontent.com/#{organisation}/#{repository}/#{branch}/#{path}"
      end

      private

      def danger_comment?(comment, danger_id)
        comment[:body].include?("generated_by_#{danger_id}")
      end
    end
  end
end
