require "danger/ci_source/support/local_pull_request"
require "danger/ci_source/support/remote_pull_request"
require "danger/ci_source/support/no_pull_request"

module Danger
  class PullRequestFinder
    def initialize(specific_pull_request_id, repo_slug = nil, remote: false, git_logs: "")
      @specific_pull_request_id = specific_pull_request_id
      @git_logs = git_logs
      @repo_slug = repo_slug
      @remote = to_boolean(remote)
    end

    def call
      check_if_any_pull_request!

      pull_request
    end

    private

    attr_reader :specific_pull_request_id, :git_logs, :repo_slug, :remote

    def to_boolean(maybe_string)
      ["true", "1", "yes", "y", true].include?(maybe_string)
    end

    def check_if_any_pull_request!
      unless pull_request.valid?
        if !specific_pull_request_id.empty?
          raise "Could not find the Pull Request (#{specific_pull_request_id}) inside the git history for this repo."
        else
          raise "No recent Pull Requests found for this repo, danger requires at least one Pull Request for the local mode.".freeze
        end
      end
    end

    # @return [String] Log line of most recent merged Pull Request
    def pull_request
      @pull_request ||= begin
        return if pull_request_ref.empty?

        if both_present?
          LocalPullRequest.new(pick_the_most_recent_one_from_two_matches)
        elsif only_merged_pull_request_present?
          LocalPullRequest.new(most_recent_merged_pull_request)
        elsif only_squash_and_merged_pull_request_present?
          LocalPullRequest.new(most_recent_squash_and_merged_pull_request)
        elsif remote && remote_pull_request
          RemotePullRequest.new(
            remote_pull_request.number.to_s,
            remote_pull_request.head.sha,
            remote_pull_request.base.sha
          )
        else
          NoPullRequest.new
        end
      end
    end

    # @return [String] "#42"
    def pull_request_ref
      !specific_pull_request_id.empty? ? "##{specific_pull_request_id}" : "#\\d+".freeze
    end

    def remote_pull_request
      @_remote_pull_request ||= begin
        client.pull_request(repo_slug, specific_pull_request_id)
      end
    end

    def both_present?
      most_recent_merged_pull_request && most_recent_squash_and_merged_pull_request
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

    def pick_the_most_recent_one_from_two_matches
      merged_index = git_logs.lines.index(most_recent_merged_pull_request)
      squash_and_merged_index = git_logs.lines.index(most_recent_squash_and_merged_pull_request)

      if merged_index > squash_and_merged_index # smaller index is more recent
        most_recent_squash_and_merged_pull_request
      else
        most_recent_merged_pull_request
      end
    end

    def only_merged_pull_request_present?
      return false if most_recent_squash_and_merged_pull_request

      !most_recent_merged_pull_request.nil? && !most_recent_merged_pull_request.empty?
    end

    def only_squash_and_merged_pull_request_present?
      return false if most_recent_merged_pull_request

      !most_recent_squash_and_merged_pull_request.nil? && !most_recent_squash_and_merged_pull_request.empty?
    end

    def client
      require "octokit"
      Octokit::Client.new(access_token: ENV["DANGER_GITHUB_API_TOKEN"], api_endpoint: api_url)
    end

    def api_url
      ENV.fetch("DANGER_GITHUB_API_HOST") do
        ENV.fetch("DANGER_GITHUB_API_BASE_URL") do
          "https://api.github.com/".freeze
        end
      end
    end
  end
end
