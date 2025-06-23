# frozen_string_literal: true

require "danger/ci_source/support/local_pull_request"
require "danger/ci_source/support/remote_pull_request"
require "danger/ci_source/support/no_pull_request"

module Danger
  class PullRequestFinder
    def initialize(specific_pull_request_id, repo_slug = nil, remote: false, git_logs: "", remote_url: "")
      @specific_pull_request_id = specific_pull_request_id
      @git_logs = git_logs
      @repo_slug = repo_slug
      @remote = to_boolean(remote)
      @remote_url = remote_url
    end

    def call(env: nil)
      find_pull_request(env).tap do |pull_request|
        raise_pull_request_not_found!(pull_request) unless pull_request.valid?
      end
    end

    private

    attr_reader :specific_pull_request_id, :git_logs, :repo_slug, :remote, :remote_url

    def to_boolean(maybe_string)
      ["true", "1", "yes", "y", true].include?(maybe_string)
    end

    def raise_pull_request_not_found!(_pull_request)
      if specific_pull_request_id.empty?
        raise "No recent Pull Requests found for this repo, danger requires at least one Pull Request for the local mode."
      else
        raise "Could not find the Pull Request (#{specific_pull_request_id}) inside the git history for this repo."
      end
    end

    # @return [String] Log line of most recent merged Pull Request
    def find_pull_request(env)
      return if pull_request_ref.empty?

      if both_present?
        LocalPullRequest.new(pick_the_most_recent_one_from_two_matches)
      elsif only_merged_pull_request_present?
        LocalPullRequest.new(most_recent_merged_pull_request)
      elsif only_squash_and_merged_pull_request_present?
        LocalPullRequest.new(most_recent_squash_and_merged_pull_request)
      elsif remote
        remote_pull_request = find_remote_pull_request(env)
        remote_pull_request ? generate_remote_pull_request(remote_pull_request) : NoPullRequest.new
      else
        NoPullRequest.new
      end
    end

    # @return [String] "#42"
    def pull_request_ref
      !specific_pull_request_id.empty? ? "##{specific_pull_request_id}" : "#\\d+"
    end

    def generate_remote_pull_request(remote_pull_request)
      scm_provider = find_scm_provider(remote_url)

      case scm_provider
      when :bitbucket_cloud
        RemotePullRequest.new(
          remote_pull_request[:id].to_s,
          remote_pull_request[:source][:commit][:hash],
          remote_pull_request[:destination][:commit][:hash]
        )
      when :bitbucket_server
        RemotePullRequest.new(
          remote_pull_request[:id].to_s,
          remote_pull_request[:fromRef][:latestCommit],
          remote_pull_request[:toRef][:latestCommit]
        )
      when :github
        RemotePullRequest.new(
          remote_pull_request.number.to_s,
          remote_pull_request.head.sha,
          remote_pull_request.base.sha
        )
      when :gitlab
        RemotePullRequest.new(
          remote_pull_request.iid.to_s,
          remote_pull_request.diff_refs.head_sha,
          remote_pull_request.diff_refs.base_sha
        )
      when :vsts
        RemotePullRequest.new(
          remote_pull_request[:pullRequestId].to_s,
          remote_pull_request[:lastMergeSourceCommit][:commitId],
          remote_pull_request[:lastMergeTargetCommit][:commitId]
        )
      else
        raise "SCM provider not supported: #{scm_provider}"
      end
    end

    def find_remote_pull_request(env)
      scm_provider = find_scm_provider(remote_url)

      if scm_provider == :gitlab
        client(env).merge_request(repo_slug, specific_pull_request_id)
      else
        client(env).pull_request(repo_slug, specific_pull_request_id)
      end
    end

    def both_present?
      most_recent_merged_pull_request && most_recent_squash_and_merged_pull_request
    end

    # @return [String] Log line of format: "Merge pull request #42"
    def most_recent_merged_pull_request
      @most_recent_merged_pull_request ||= git_logs.lines.grep(/Merge pull request #{pull_request_ref} from/)[0]
    end

    # @return [String] Log line of format: "description (#42)"
    def most_recent_squash_and_merged_pull_request
      @most_recent_squash_and_merged_pull_request ||= git_logs.lines.grep(/\(#{pull_request_ref}\)/)[0]
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

    def client(env)
      scm_provider = find_scm_provider(remote_url)

      case scm_provider
      when :bitbucket_cloud
        bitbucket_cloud_client(env)
      when :bitbucket_server
        bitbucket_server_client(env)
      when :vsts
        vsts_client(env)
      when :gitlab
        gitlab_client(env)
      when :github
        github_client(env)
      else
        raise "SCM provider not supported: #{scm_provider}"
      end
    end

    def bitbucket_cloud_client(env)
      require "danger/request_sources/bitbucket_cloud_api"
      branch_name = ENV["DANGER_BITBUCKET_TARGET_BRANCH"] # Optional env variable (specifying the target branch) to help find the PR.
      RequestSources::BitbucketCloudAPI.new(repo_slug, specific_pull_request_id, branch_name, env)
    end

    def bitbucket_server_client(env)
      require "danger/request_sources/bitbucket_server_api"
      project, slug = repo_slug.split("/")
      RequestSources::BitbucketServerAPI.new(project, slug, specific_pull_request_id, env)
    end

    def vsts_client(env)
      require "danger/request_sources/vsts_api"
      RequestSources::VSTSAPI.new(repo_slug, specific_pull_request_id, env)
    end

    def gitlab_client(env)
      require "gitlab"
      token = env&.fetch("DANGER_GITLAB_API_TOKEN", nil) || ENV["DANGER_GITLAB_API_TOKEN"]
      if token && !token.empty?
        endpoint = env&.fetch("DANGER_GITLAB_API_BASE_URL", nil) || env&.fetch("CI_API_V4_URL", nil) || ENV["DANGER_GITLAB_API_BASE_URL"] || ENV.fetch("CI_API_V4_URL", "https://gitlab.com/api/v4")
        Gitlab.client(endpoint: endpoint, private_token: token)
      else
        raise "No API token given, please provide one using `DANGER_GITLAB_API_TOKEN`"
      end
    end

    def github_client(env)
      require "octokit"
      access_token = env&.fetch("DANGER_GITHUB_API_TOKEN", nil) || ENV["DANGER_GITHUB_API_TOKEN"]
      bearer_token = env&.fetch("DANGER_GITHUB_BEARER_TOKEN", nil) || ENV["DANGER_GITHUB_BEARER_TOKEN"]
      if bearer_token && !bearer_token.empty?
        Octokit::Client.new(bearer_token: bearer_token, api_endpoint: api_url)
      elsif access_token && !access_token.empty?
        Octokit::Client.new(access_token: access_token, api_endpoint: api_url)
      else
        raise "No API token given, please provide one using `DANGER_GITHUB_API_TOKEN` or `DANGER_GITHUB_BEARER_TOKEN`"
      end
    end

    def api_url
      ENV.fetch("DANGER_GITHUB_API_HOST") do
        ENV.fetch("DANGER_GITHUB_API_BASE_URL") do
          "https://api.github.com/"
        end
      end
    end

    def find_scm_provider(remote_url)
      case remote_url
      when %r{/bitbucket.org/}
        :bitbucket_cloud
      when %r{/pull-requests/}
        :bitbucket_server
      when /\.visualstudio\.com/i, /dev\.azure\.com/i
        :vsts
      when /gitlab\.com/, %r{-/merge_requests/}
        :gitlab
      else
        :github
      end
    end
  end
end
