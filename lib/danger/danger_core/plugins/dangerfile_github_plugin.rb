require "danger/plugin_support/plugin"

module Danger
  # Handles interacting with GitHub inside a Dangerfile. Provides a few functions which wrap `pr_json` and also
  # through a few standard functions to simplify your code.
  #
  # @example Warn when a PR is classed as work in progress
  #
  #          warn "PR is classed as Work in Progress" if github.pr_title.include? "[WIP]"
  #
  # @example Declare a PR to be simple to avoid specific Danger rules
  #
  #          declared_trivial = (github.pr_title + github.pr_body).include?("#trivial")
  #
  # @example Ensure that labels have been used on the PR
  #
  #          failure "Please add labels to this PR" if github.pr_labels.empty?
  #
  # @example Check if a user is in a specific GitHub org, and message them if so
  #
  #          unless github.api.organization_member?('danger', github.pr_author)
  #            message "@#{github.pr_author} is not a contributor yet, would you like to join the Danger org?"
  #          end
  #
  # @example Ensure there is a summary for a PR
  #
  #          failure "Please provide a summary in the Pull Request description" if github.pr_body.length < 5
  #
  # @example Only accept PRs to the develop branch
  #
  #          failure "Please re-submit this PR to develop, we may have already fixed your issue." if github.branch_for_base != "develop"
  #
  # @example Note when PRs don't reference a milestone, which goes away when it does
  #
  #          has_milestone = github.pr_json["milestone"] != nil
  #          warn("This PR does not refer to an existing milestone", sticky: false) unless has_milestone
  #
  # @example Note when a PR cannot be manually merged, which goes away when you can
  #
  #          can_merge = github.pr_json["mergeable"]
  #          warn("This PR cannot be merged yet.", sticky: false) unless can_merge
  #
  # @example Highlight when a celebrity makes a pull request
  #
  #          message "Welcome, Danger." if github.pr_author == "dangermcshane"
  #
  # @example Ensure that all PRs have an assignee
  #
  #          warn "This PR does not have any assignees yet." unless github.pr_json["assignee"]
  #
  # @example Send a message with links to a collection of specific files
  #
  #          if git.modified_files.include? "config/*.js"
  #            config_files = git.modified_files.select { |path| path.include? "config/" }
  #            message "This PR changes #{ github.html_link(config_files) }"
  #          end
  #
  # @example Highlight with a clickable link if a Package.json is changed
  #
  #         warn "#{github.html_link("Package.json")} was edited." if git.modified_files.include? "Package.json"
  #
  # @example Note an issue with a particular line on a file using the #L[num] syntax, e.g. `#L23`
  #
  #         linter_json = `my_linter lint "file"`
  #         results = JSON.parse linter_json
  #         unless results.empty?
  #           file, line, warning = result.first
  #           warn "#{github.html_link("#{file}#L#{line}")} has linter issue: #{warning}."
  #         end
  #
  #
  # @see  danger/danger
  # @tags core, github
  #
  class DangerfileGitHubPlugin < Plugin
    # So that this init can fail.
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::GitHub
      super
    end

    def initialize(dangerfile)
      super(dangerfile)

      @github = dangerfile.env.request_source
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "github"
    end

    # @!group PR Review
    #
    # In Beta. Provides access to creating a GitHub Review instead of a typical GitHub comment.
    #
    # To use you announce the start of your review, and the end via the `start` and `submit` functions,
    # for example:
    #
    # github.review.start
    # github.review.fail(message)
    # github.review.warn(message)
    # github.review.message(message)
    # github.review.markdown(message)
    # github.review.submit
    #
    # @return [ReviewDSL]
    def review
      @github.review
    end

    # @!group PR Metadata
    # The title of the Pull Request.
    # @return [String]
    #
    def pr_title
      @github.pr_json["title"].to_s
    end

    # @!group PR Metadata
    # The body text of the Pull Request.
    # @return [String]
    #
    def pr_body
      pr_json["body"].to_s
    end

    # @!group PR Metadata
    # The username of the author of the Pull Request.
    # @return [String]
    #
    def pr_author
      pr_json["user"]["login"].to_s
    end

    # @!group PR Metadata
    # The labels assigned to the Pull Request.
    # @return [String]
    #
    def pr_labels
      @github.issue_json["labels"].map { |l| l[:name] }
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged into.
    # @return [String]
    #
    def branch_for_base
      pr_json["base"]["ref"]
    end

    # @!group PR Commit Metadata
    # The branch to which the PR is going to be merged from.
    # @return [String]
    #
    def branch_for_head
      pr_json["head"]["ref"]
    end

    # @!group PR Commit Metadata
    # The base commit to which the PR is going to be merged as a parent.
    # @return [String]
    #
    def base_commit
      pr_json["base"]["sha"]
    end

    # @!group PR Commit Metadata
    # The head commit to which the PR is requesting to be merged from.
    # @return [String]
    #
    def head_commit
      pr_json["head"]["sha"]
    end

    # @!group GitHub Misc
    # The hash that represents the PR's JSON. For an example of what this looks like
    # see the [Danger Fixture'd one](https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/github_api/pr_response.json).
    # @return [Hash]
    #
    def pr_json
      @github.pr_json
    end

    # @!group GitHub Misc
    # Provides access to the GitHub API client used inside Danger. Making
    # it easy to use the GitHub API inside a Dangerfile.
    # @return [Octokit::Client]
    def api
      @github.client
    end

    # @!group PR Content
    # The unified diff produced by Github for this PR
    # see [Unified diff](https://en.wikipedia.org/wiki/Diff_utility#Unified_format)
    # @return [String]
    def pr_diff
      @github.pr_diff
    end

    # @!group GitHub Misc
    # Returns a list of HTML anchors for a file, or files in the head repository. An example would be:
    # `<a href='https://github.com/artsy/eigen/blob/561827e46167077b5e53515b4b7349b8ae04610b/file.txt'>file.txt</a>`. It returns a string of multiple anchors if passed an array.
    # @param    [String or Array<String>] paths
    #           A list of strings to convert to github anchors
    # @param    [Bool] full_path
    #           Shows the full path as the link's text, defaults to `true`.
    #
    # @return [String]
    def html_link(paths, full_path: true)
      paths = [paths] unless paths.kind_of?(Array)
      commit = head_commit
      repo = pr_json["head"]["repo"]["html_url"]

      paths = paths.map do |path|
        url_path = path.start_with?("/") ? path : "/#{path}"
        text = full_path ? path : File.basename(path)
        create_link("#{repo}/blob/#{commit}#{url_path}", text)
      end

      return paths.first if paths.count < 2
      paths.first(paths.count - 1).join(", ") + " & " + paths.last
    end

    # @!group GitHub Misc
    # Use to ignore inline messages which lay outside a diff's range, thereby not posting them in the main comment.
    # You can set hash to change behavior per each kinds. (ex. `{warning: true, error: false}`)
    # @param    [Bool] or [Hash<Symbol, Bool>] dismiss
    #           Ignore out of range inline messages, defaults to `true`
    #
    # @return   [void]
    def dismiss_out_of_range_messages(dismiss = true)
      if dismiss.kind_of?(Hash)
        @github.dismiss_out_of_range_messages = dismiss
      elsif dismiss.kind_of?(TrueClass)
        @github.dismiss_out_of_range_messages = true
      elsif dismiss.kind_of?(FalseClass)
        @github.dismiss_out_of_range_messages = false
      end
    end

    %i(title body author labels json).each do |suffix|
      alias_method "mr_#{suffix}".to_sym, "pr_#{suffix}".to_sym
    end

    private

    def create_link(href, text)
      "<a href='#{href}'>#{text}</a>"
    end
  end
end
