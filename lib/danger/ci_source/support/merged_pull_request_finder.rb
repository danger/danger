module Danger
  class MergedPullRequestFinder
    def initialize(specific_pull_request_id, git_logs)
      @specific_pull_request_id = specific_pull_request_id
      @git_logs = git_logs
    end

    def call
      check_if_any_merged_pull_request!

      [merged_pull_request_id, merged_pull_request_sha]
    end

    private

    attr_reader :specific_pull_request_id, :git_logs

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

    # @return [String] Log line of most recent merged Pull Request
    def merged_pull_request
      return if pull_request_ref.empty?

      if both_present?
        pick_the_most_recent_one_from_two_matches
      elsif only_merged_pull_request_present?
        most_recent_merged_pull_request
      elsif only_squash_and_merged_pull_request_present?
        most_recent_squash_and_merged_pull_request
      end
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

    def check_if_any_merged_pull_request!
      if merged_pull_request.to_s.empty?
        if !specific_pull_request_id.empty?
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
