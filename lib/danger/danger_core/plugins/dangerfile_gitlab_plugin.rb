require "danger/plugin_support/plugin"

module Danger
  class DangerfileGitLabPlugin < Plugin
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::GitLab

      super
    end

    def self.instance_name
      "gitlab"
    end

    def initialize(dangerfile)
      super(dangerfile)

      @gitlab = dangerfile.env.request_source
    end

    # @!group PR Metadata
    # The title of the Pull Request
    # @return String
    #
    def pr_title
      @gitlab.mr_json.title.to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request
    # @return String
    #
    def pr_body
      @gitlab.mr_json.description.to_s
    end

    # @!group PR Metadata
    # The username of the author of the Pull Request
    # @return String
    #
    def pr_author
      @gitlab.mr_json.author.username.to_s
    end

    # @!group PR Metadata
    # The labels assigned to the Pull Request
    # @return [String]
    #
    def pr_labels
      @gitlab.mr_json.labels
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into
    # @return String
    #
    def branch_for_merge
      @gitlab.mr_json.target_branch
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent
    # @return String
    #
    def base_commit
      @gitlab.base_commit
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from
    # @return String
    #
    def head_commit
      @gitlab.commits_json.first.id
    end

    # @!group GitLab Misc
    # The hash that represents the MR's JSON. See documentation for the
    # structure [here](http://docs.gitlab.com/ce/api/merge_requests.html#get-single-mr)
    # @return [Hash]
    #
    def pr_json
      @gitlab.pr_json
    end

    # @!group GitLab Misc
    # Provides access to the GitLab API client used inside Danger. Making
    # it easy to use the GitLab API inside a Dangerfile.
    # @return [GitLab::Client]
    def api
      @gitlab.client
    end

    [:title, :body, :author, :labels, :json].each do |suffix|
      alias_method "mr_#{suffix}".to_sym, "pr_#{suffix}".to_sym
    end
  end
end
