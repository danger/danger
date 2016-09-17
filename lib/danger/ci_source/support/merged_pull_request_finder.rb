module Danger
  class MergedPullRequestFinder
    def initialize(specific_pull_request_id:, git:)
      @specific_pull_request_id = specific_pull_request_id
      @git = git
    end

    def call
      check_if_any_merged_pull_request!

      [merged_pull_request_id, merged_pull_request_sha]
    end

    private

    attr_reader :specific_pull_request_id, :git

    def run_git(command)
      git.exec(command)
    end

    # @return [String] "#42"
    def pull_request_ref
      specific_pull_request_id ? "##{specific_pull_request_id}" : "".freeze
    end

    # @return [Array] Recent 50 commit logs in oneliner
    def git_logs
      @git_logs ||= run_git("log --oneline -50".freeze)
    end

    # @return [String] Log line of format: "Merge pull request #42"
    def most_recent_merged_pull_request
      @last_merged_pull_request ||= begin
        git_logs.lines.grep(/Merge pull request #{pull_request_ref}/)[0]
      end
    end

    # @return [String] Log line of format: "description (#42)"
    def most_recent_squash_and_merged_pull_request
      @last_merged_pull_request ||= begin
        git_logs.lines.grep(/#{pull_request_ref}/)[0]
      end
    end

    # @return [String] Log line of most recent merged Pull Request
    def merged_pull_request
      return if pull_request_ref.empty?

      if most_recent_merged_pull_request
        most_recent_merged_pull_request
      elsif most_recent_squash_and_merged_pull_request
        most_recent_squash_and_merged_pull_request
      end
    end

    def check_if_any_merged_pull_request!
      if merged_pull_request.to_s.empty?
        if specific_pull_request_id
          raise "Could not find the Pull Request (#{specific_pull_request_id}) inside the git history for this repo."
        else
          raise "No recent Pull Requests found for this repo, danger requires at least one Pull Request for the local mode.".freeze
        end
      end
    end

    def merged_pull_request_id
      merged_pull_request.match(/#(?<id>[0-9]+)/)[:id]
    end

    def merged_pull_request_sha
      merged_pull_request.split(" ".freeze).first
    end
  end
end
