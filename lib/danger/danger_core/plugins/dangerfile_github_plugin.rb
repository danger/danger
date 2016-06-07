require 'danger/plugin_support/plugin'

module Danger
  class DangerfileGitHubPlugin < Plugin
    def initialize(dangerfile)
      super(dangerfile)
      return nil unless dangerfile.env.request_source.class == Danger::RequestSources::GitHub

      @github = dangerfile.env.request_source
    end

    # @!group PR Metadata
    # The title of the Pull Request
    # @return String
    #
    def pr_title
      @github.pr_json[:title].to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request
    # @return String
    #
    def pr_body
      @github.pr_json[:body].to_s
    end

    # @!group PR Metadata
    # The username of the author of the Pull Request
    # @return String
    #
    def pr_author
      @github.pr_json[:user][:login].to_s
    end

    # @!group PR Metadata
    # The labels assigned to the Pull Request
    # @return [String]
    #
    def pr_labels
      @github.issue_json[:labels].map { |l| l[:name] }
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into
    # @return String
    #
    def branch_for_merge
      @github.pr_json[:base][:ref]
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent
    # @return String
    #
    def base_commit
      @github.pr_json[:base][:sha]
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from
    # @return String
    #
    def head_commit
      @github.pr_json[:head][:sha]
    end
  end
end
