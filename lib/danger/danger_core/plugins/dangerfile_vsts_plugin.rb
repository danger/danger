# coding: utf-8

require "danger/plugin_support/plugin"

module Danger
  # Handles interacting with VSTS inside a Dangerfile. Provides a few functions which wrap `pr_json` and also
  # through a few standard functions to simplify your code.
  #
  # @example Warn when a PR is classed as work in progress
  #
  #          warn "PR is classed as Work in Progress" if vsts.pr_title.include? "[WIP]"
  #
  # @example Declare a PR to be simple to avoid specific Danger rules
  #
  #          declared_trivial = (vsts.pr_title + vsts.pr_body).include?("#trivial")
  #
  # @example Ensure there is a summary for a PR
  #
  #          failure "Please provide a summary in the Pull Request description" if vsts.pr_body.length < 5
  #
  # @example Only accept PRs to the develop branch
  #
  #          failure "Please re-submit this PR to develop, we may have already fixed your issue." if vsts.branch_for_base != "develop"
  #
  # @example Highlight when a celebrity makes a pull request
  #
  #          message "Welcome, Danger." if vsts.pr_author == "dangermcshane"
  #
  # @example Ensure that all PRs have an assignee
  #
  #          warn "This PR does not have any assignees yet." unless vsts.pr_json["reviewers"].length == 0
  #
  # @example Send a message with links to a collection of specific files
  #
  #          if git.modified_files.include? "config/*.js"
  #            config_files = git.modified_files.select { |path| path.include? "config/" }
  #            message "This PR changes #{ vsts.markdown_link(config_files) }"
  #          end
  #
  # @example Highlight with a clickable link if a Package.json is changed
  #
  #         warn "#{vsts.markdown_link("Package.json")} was edited." if git.modified_files.include? "Package.json"
  #
  # @example Note an issue with a particular line on a file using the #L[num] syntax, e.g. `#L23`
  #
  #         linter_json = `my_linter lint "file"`
  #         results = JSON.parse linter_json
  #         unless results.empty?
  #           file, line, warning = result.first
  #           warn "#{vsts.markdown_link("#{file}#L#{line}")} has linter issue: #{warning}."
  #         end
  #
  #
  # @see  danger/danger
  # @tags core, vsts
  #
  class DangerfileVSTSPlugin < Plugin
    # So that this init can fail.
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::VSTS
      super
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "vsts"
    end

    def initialize(dangerfile)
      super(dangerfile)
      @source = dangerfile.env.request_source
    end

    # @!group VSTS Misc
    # The hash that represents the PR's JSON. For an example of what this looks like
    # see the [Danger Fixture'd one](https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/vsts_api/pr_response.json).
    # @return [Hash]
    def pr_json
      @source.pr_json
    end

    # @!group PR Metadata
    # The title of the Pull Request.
    # @return [String]
    #
    def pr_title
      @source.pr_json[:title].to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request.
    # @return [String]
    #
    def pr_description
      @source.pr_json[:description].to_s
    end
    alias pr_body pr_description

    # @!group PR Metadata
    # The username of the author of the Pull Request.
    # @return [String]
    #
    def pr_author
      @source.pr_json[:createdBy][:displayName].to_s
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into.
    # @return [String]
    #
    def branch_for_base
      branch_name(:targetRefName)
    end

    # @!group PR Commit Metadata
    # A href that represents the current PR
    # @return [String]
    #
    def pr_link
      repo_path = @source.pr_json[:repository][:remoteUrl].to_s
      pull_request_id = @source.pr_json[:pullRequestId].to_s

      "#{repo_path}/pullRequest/#{pull_request_id}"
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged from.
    # @return [String]
    #
    def branch_for_head
      branch_name(:sourceRefName)
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent.
    # @return [String]
    #
    def base_commit
      @source.pr_json[:lastMergeTargetCommit][:commitId].to_s
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from.
    # @return [String]
    #
    def head_commit
      @source.pr_json[:lastMergeSourceCommit][:commitId].to_s
    end

    # @!group VSTS Misc
    # Returns a list of Markdown links for a file, or files in the head repository.
    # It returns a string of multiple links if passed an array.
    # @param    [String or Array<String>] paths
    #           A list of strings to convert to Markdown links
    # @param    [Bool] full_path
    #           Shows the full path as the link's text, defaults to `true`.
    #
    # @return [String]
    #
    def markdown_link(paths, full_path: true)
      paths = [paths] unless paths.kind_of?(Array)
      commit = head_commit
      repo = pr_json[:repository][:remoteUrl].to_s

      paths = paths.map do |path|
        path, line = path.split("#L")
        url_path = path.start_with?("/") ? path : "/#{path}"
        text = full_path ? path : File.basename(path)
        url_path.gsub!(" ", "%20")
        line_ref = line ? "&line=#{line}" : ""
        create_markdown_link("#{repo}/commit/#{commit}?path=#{url_path}&_a=contents#{line_ref}", text)
      end

      return paths.first if paths.count < 2
      paths.first(paths.count - 1).join(", ") + " & " + paths.last
    end

    private

    def create_markdown_link(href, text)
      "[#{text}](#{href})"
    end

    def branch_name(key)
      repo_matches = @source.pr_json[key].to_s.match(%r{refs\/heads\/(.*)})
      repo_matches[1] unless repo_matches.nil?
    end
  end
end
