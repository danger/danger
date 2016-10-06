require "danger/ci_source/support/open_pull_request"
require "danger/ci_source/support/result"

module Danger
  class PullRequestFinder
    def initialize(specific_pull_request_id, git_logs, repo_slug = nil, check_open_pr = false)
      @specific_pull_request_id = specific_pull_request_id
      @git_logs = git_logs
      @need_to_check_open_pr = check_open_pr == "true" ? true : false

      if need_to_check_open_pr
        @repo_slug = repo_slug
        if !repo_slug
          raise "danger pr requires a repository hosted on GitHub.com or GitHub Enterprise.".freeze
        end
      end
    end

    def call
      check_if_any_pull_request!

      pull_request
    end

    private

    attr_reader :specific_pull_request_id, :git_logs, :repo_slug, :need_to_check_open_pr

    # @return [String] "#42"
    def pull_request_ref
      !specific_pull_request_id.empty? ? "##{specific_pull_request_id}" : "#\\d+".freeze
    end

    # @return [String] Log line of format: "Merge pull request #42"
    def most_recent_merged_pull_request
      @most_recent_merged_pull_request ||= begin
        git_logs.lines.grep(/Merge pull request #{pull_request_ref} from/)[0]
      end
    end

    # @return [String] Log line of format: "description (#42)"
    def most_recent_squash_and_merged_pull_request
      @most_recent_squash_and_merged_pull_request ||= begin
        git_logs.lines.grep(/\(#{pull_request_ref}\)/)[0]
      end
    end

    class NoResult
      def valid?
        false
      end
    end

    # @return [String] Log line of most recent merged Pull Request
    def pull_request
      @pull_request ||= begin
        return if pull_request_ref.empty?

        if both_present?
          Result.new(pick_the_most_recent_one_from_two_matches)
        elsif only_merged_pull_request_present?
          Result.new(most_recent_merged_pull_request)
        elsif only_squash_and_merged_pull_request_present?
          Result.new(most_recent_squash_and_merged_pull_request)
        elsif need_to_check_open_pr && found_matched_opened_pr
          Result.new(nil, found_matched_opened_pr.number, found_matched_opened_pr.head, found_matched_opened_pr.base)
        else
          NoResult.new
        end
      end
    end

    def found_matched_opened_pr
      @found_matched_opened_pr ||= begin
        open_pull_requests.find do |open_pr|
          specific_pull_request_id == open_pr.number
        end
      end
    end

    def open_pull_requests
      @open_pull_requests ||= begin
        client.pull_requests(repo_slug).
          select { |pr| pr.state == "open" }
          .map do |open_pr|
            OpenPullRequest.new(
              open_pr.number.to_s,
              open_pr.title,
              open_pr.head.sha,
              open_pr.base.sha
            )
          end
      end
    end

    def client
      Octokit::Client.new(access_token: ENV["DANGER_GITHUB_API_TOKEN"])
    end

    def both_present?
      most_recent_merged_pull_request && most_recent_squash_and_merged_pull_request
    end

    def only_merged_pull_request_present?
      return false if most_recent_squash_and_merged_pull_request

      !most_recent_merged_pull_request.nil? && !most_recent_merged_pull_request.empty?
    end

    def only_squash_and_merged_pull_request_present?
      return false if most_recent_merged_pull_request

      !most_recent_squash_and_merged_pull_request.nil? && !most_recent_squash_and_merged_pull_request.empty?
    end

    def pick_the_most_recent_one_from_two_matches
      merged_index = git_logs.lines.index(most_recent_merged_pull_request)
      squash_and_merged_index = git_logs.lines.index(most_recent_squash_and_merged_pull_request)

      if merged_index > squash_and_merged_index # smaller index is more recent
        most_recent_squash_and_merged_pull_request
      else
        most_recent_merged_pull_request
      end
    end

    def check_if_any_pull_request!
      if !pull_request.valid?
        if !specific_pull_request_id.empty?
          raise "Could not find the Pull Request (#{specific_pull_request_id}) inside the git history for this repo."
        else
          raise "No recent Pull Requests found for this repo, danger requires at least one Pull Request for the local mode.".freeze
        end
      end
    end
  end
end
