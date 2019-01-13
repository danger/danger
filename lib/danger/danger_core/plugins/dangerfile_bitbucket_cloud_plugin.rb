# coding: utf-8

require "danger/plugin_support/plugin"

module Danger
  # Handles interacting with Bitbucket Cloud inside a Dangerfile. Provides a few functions which wrap `pr_json` and also
  # through a few standard functions to simplify your code.
  #
  # @example Warn when a PR is classed as work in progress
  #
  #          warn "PR is classed as Work in Progress" if bitbucket_cloud.pr_title.include? "[WIP]"
  #
  # @example Declare a PR to be simple to avoid specific Danger rules
  #
  #          declared_trivial = (bitbucket_cloud.pr_title + bitbucket_cloud.pr_body).include?("#trivial")
  #
  # @example Ensure that labels have been used on the PR
  #
  #          failure "Please add labels to this PR" if bitbucket_cloud.pr_labels.empty?
  #
  # @example Ensure there is a summary for a PR
  #
  #          failure "Please provide a summary in the Pull Request description" if bitbucket_cloud.pr_body.length < 5
  #
  # @example Only accept PRs to the develop branch
  #
  #          failure "Please re-submit this PR to develop, we may have already fixed your issue." if bitbucket_cloud.branch_for_base != "develop"
  #
  # @example Highlight when a celebrity makes a pull request
  #
  #          message "Welcome, Danger." if bitbucket_cloud.pr_author == "dangermcshane"
  #
  # @example Ensure that all PRs have an assignee
  #
  #          warn "This PR does not have any assignees yet." if bitbucket_cloud.pr_json[:reviewers].length == 0
  #
  # @example Send a message with links to a collection of specific files
  #
  #          if git.modified_files.include? "config/*.js"
  #            config_files = git.modified_files.select { |path| path.include? "config/" }
  #            message "This PR changes #{ bitbucket_cloud.html_link(config_files) }"
  #          end
  #
  # @example Highlight with a clickable link if a Package.json is changed
  #
  #         warn "#{bitbucket_cloud.html_link("Package.json")} was edited." if git.modified_files.include? "Package.json"
  #
  # @see  danger/danger
  # @tags core, bitbucket_cloud
  #
  class DangerfileBitbucketCloudPlugin < Plugin
    # So that this init can fail.
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::BitbucketCloud
      super
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "bitbucket_cloud"
    end

    def initialize(dangerfile)
      super(dangerfile)
      @bs = dangerfile.env.request_source
    end

    # @!group Bitbucket Cloud Misc
    # The hash that represents the PR's JSON. For an example of what this looks like
    # see the [Danger Fixture'd one](https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/bitbucket_cloud_api/pr_response.json).
    # @return [Hash]
    def pr_json
      @bs.pr_json
    end

    # @!group PR Metadata
    # The title of the Pull Request.
    # @return [String]
    #
    def pr_title
      @bs.pr_json[:title].to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request.
    # @return [String]
    #
    def pr_description
      @bs.pr_json[:description].to_s
    end
    alias pr_body pr_description

    # @!group PR Metadata
    # The username of the author of the Pull Request.
    # @return [String]
    #
    def pr_author
      @bs.pr_json[:author][:username]
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into.
    # @return [String]
    #
    def branch_for_base
      @bs.pr_json[:destination][:branch][:name]
    end

    # @!group PR Commit Metadata
    # A href that represents the current PR
    # @return [String]
    #
    def pr_link
      @bs.pr_json[:links][:self][:href]
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged from.
    # @return [String]
    #
    def branch_for_head
      @bs.pr_json[:destination][:branch][:name]
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent.
    # @return [String]
    #
    def base_commit
      @bs.pr_json[:destination][:commit][:hash]
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from.
    # @return [String]
    #
    def head_commit
      @bs.pr_json[:source][:commit][:hash]
    end

  end
end
