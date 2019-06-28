require "danger/plugin_support/plugin"

module Danger
  # Handles interacting with GitLab inside a Dangerfile. Provides a few functions which wrap `mr_json` and also
  # through a few standard functions to simplify your code.
  #
  # @example Warn when an MR is classed as work in progress.
  #
  #          warn "MR is classed as Work in Progress" if gitlab.mr_title.include? "[WIP]"
  #
  # @example Declare a MR to be simple to avoid specific Danger rules.
  #
  #          declared_trivial = (gitlab.mr_title + gitlab.mr_body).include?("#trivial")
  #
  # @example Ensure that labels have been applied to the MR.
  #
  #          failure "Please add labels to this MR" if gitlab.mr_labels.empty?
  #
  # @example Ensure that all MRs have an assignee.
  #
  #          warn "This MR does not have any assignees yet." unless gitlab.mr_json["assignee"]
  #
  # @example Ensure there is a summary for a MR.
  #
  #          failure "Please provide a summary in the Merge Request description" if gitlab.mr_body.length < 5
  #
  # @example Only accept MRs to the develop branch.
  #
  #          failure "Please re-submit this MR to develop, we may have already fixed your issue." if gitlab.branch_for_merge != "develop"
  #
  # @example Note when MRs don't reference a milestone, make the warning stick around on subsequent runs
  #
  #          has_milestone = gitlab.mr_json["milestone"] != nil
  #          warn("This MR does not refer to an existing milestone", sticky: true) unless has_milestone
  #
  # @example Note when a MR cannot be manually merged
  #
  #          can_merge = gitlab.mr_json["mergeable"]
  #          warn("This MR cannot be merged yet.") unless can_merge
  #
  # @example Highlight when a celebrity makes a merge request.
  #
  #          message "Welcome, Danger." if gitlab.mr_author == "dangermcshane"
  #
  # @example Send a message with links to a collection of specific files.
  #
  #          if git.modified_files.include? "config/*.js"
  #            config_files = git.modified_files.select { |path| path.include? "config/" }
  #            message "This MR changes #{ gitlab.html_link(config_files) }"
  #          end
  #
  # @example Highlight with a clickable link if a Package.json is changed.
  #
  #         warn "#{gitlab.html_link("Package.json")} was edited." if git.modified_files.include? "Package.json"
  #
  #
  # @see  danger/danger
  # @tags core, gitlab
  #
  class DangerfileGitLabPlugin < Plugin
    # So that this init can fail.
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::GitLab
      super
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "gitlab"
    end

    def initialize(dangerfile)
      super(dangerfile)

      @gitlab = dangerfile.env.request_source
    end

    # @!group MR Metadata
    # The title of the Merge Request
    # @return [String]
    #
    def mr_title
      @gitlab.mr_json.title.to_s
    end

    # @!group MR Metadata
    # The body text of the Merge Request
    # @return [String]
    #
    def mr_body
      @gitlab.mr_json.description.to_s
    end

    # @!group MR Metadata
    # The username of the author of the Merge Request
    # @return [String]
    #
    def mr_author
      @gitlab.mr_json.author.username.to_s
    end

    # @!group MR Metadata
    # The labels assigned to the Merge Request
    # @return [String]
    #
    def mr_labels
      @gitlab.mr_json.labels
    end

    # @!group MR Content
    # The unified diff produced by GitLab for this MR
    # see [Unified diff](https://en.wikipedia.org/wiki/Diff_utility#Unified_format)
    # @return [String]
    #
    def mr_diff
      @gitlab.mr_diff
    end

    # @!group MR Commit Metadata
    # The branch to which the MR is going to be merged into
    # @deprecated Please use {#branch_for_base} instead
    # @return [String]
    #
    def branch_for_merge
      branch_for_base
    end

    # @!group MR Commit Metadata
    # The branch to which the MR is going to be merged into.
    # @return [String]
    #
    def branch_for_base
      @gitlab.mr_json.target_branch
    end

    # @!group MR Commit Metadata
    # The branch to which the MR is going to be merged from.
    # @return [String]
    #
    def branch_for_head
      @gitlab.mr_json.source_branch
    end

    # @!group MR Commit Metadata
    # The base commit to which the MR is going to be merged as a parent
    # @return [String]
    #
    def base_commit
      @gitlab.mr_json.diff_refs.base_sha
    end

    # @!group MR Commit Metadata
    # The head commit to which the MR is requesting to be merged from
    # @return [String]
    #
    def head_commit
      @gitlab.mr_json.diff_refs.head_sha
    end

    # @!group GitLab Misc
    # The hash that represents the MR's JSON. See documentation for the
    # structure [here](http://docs.gitlab.com/ce/api/merge_requests.html#get-single-mr)
    # @return [Hash]
    #
    def mr_json
      @gitlab.mr_json.to_hash
    end

    # @!group GitLab Misc
    # Provides access to the GitLab API client used inside Danger. Making
    # it easy to use the GitLab API inside a Dangerfile. See the gitlab
    # gem's [documentation](http://www.rubydoc.info/gems/gitlab/Gitlab/Client)
    # for accessible methods.
    # @return [GitLab::Client]
    #
    def api
      @gitlab.client
    end

    # @!group GitLab Misc
    # Returns a list of HTML anchors for a file, or files in the head repository. An example would be:
    # `<a href='https://gitlab.com/artsy/eigen/blob/561827e46167077b5e53515b4b7349b8ae04610b/file.txt'>file.txt</a>`. It returns a string of multiple anchors if passed an array.
    # @param    [String or Array<String>] paths
    #           A list of strings to convert to gitlab anchors
    # @param    [Bool] full_path
    #           Shows the full path as the link's text, defaults to `true`.
    #
    # @return [String]
    #
    def html_link(paths, full_path: true)
      paths = [paths] unless paths.kind_of?(Array)
      commit = head_commit

      paths = paths.map do |path|
        url_path = path.start_with?("/") ? path : "/#{path}"
        text = full_path ? path : File.basename(path)
        create_link("#{env.ci_source.project_url}/blob/#{commit}#{url_path}", text)
      end

      return paths.first if paths.count < 2
      paths.first(paths.count - 1).join(", ") + " & " + paths.last
    end

    %i(title body author labels json diff).each do |suffix|
      alias_method "pr_#{suffix}".to_sym, "mr_#{suffix}".to_sym
    end

    private

    def create_link(href, text)
      "<a href='#{href}'>#{text}</a>"
    end
  end
end
