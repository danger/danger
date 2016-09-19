require "danger/commands/local_helpers/http_cache"
require "faraday/http_cache"
require "fileutils"
require "octokit"
require "tmpdir"

module Danger
  class Local < Runner
    self.summary = "Run the Dangerfile locally."
    self.command = "local"

    def initialize(argv)
      @pr_num = argv.option("use-merged-pr")
      @clear_http_cache = argv.flag?("clear-http-cache", false)

      super

      setup_pry if should_pry?(argv)
    end

    def should_pry?(argv)
      argv.flag?("pry", false) && !@dangerfile_path.empty? && validate_pry_available
    end

    def setup_pry
      File.delete "_Dangerfile.tmp" if File.exist? "_Dangerfile.tmp"
      FileUtils.cp @dangerfile_path, "_Dangerfile.tmp"
      File.open("_Dangerfile.tmp", "a") do |f|
        f.write("binding.pry; File.delete(\"_Dangerfile.tmp\")")
      end
      @dangerfile_path = "_Dangerfile.tmp"
    end

    def validate_pry_available
      require "pry"
    rescue LoadError
      cork.warn "Pry was not found, and is required for 'danger local --pry'."
      cork.print_warnings
      abort
    end

    def self.options
      [
        ["--use-merged-pr=[#id]", "The ID of an already merged PR inside your history to use as a reference for the local run."],
        ["--clear-http-cache", "Clear the local http cache before running Danger locally."],
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
      ].concat(super)
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def run
      ENV["DANGER_USE_LOCAL_GIT"] = "YES"
      ENV["LOCAL_GIT_PR_ID"] = @pr_num if @pr_num

      # setup caching for Github calls to hitting the API rate limit too quickly
      cache_file = File.join(ENV["DANGER_TMPDIR"] || Dir.tmpdir, "danger_local_cache")
      cache = HTTPCache.new(cache_file, clear_cache: @clear_http_cache)
      Octokit.middleware = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, store: cache, serializer: Marshal, shared_cache: false
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end

      env = EnvironmentManager.new(ENV)
      dm = Dangerfile.new(env, cork)
      dm.init_plugins

      source = dm.env.ci_source
      if source.nil? or source.repo_slug.empty?
        cork.puts "danger local failed because it only works with GitHub projects at the moment. Sorry.".red
        exit 0
      end

      gh = dm.env.request_source

      cork.puts "Running your Dangerfile against this PR - https://#{gh.host}/#{source.repo_slug}/pull/#{source.pull_request_id}"

      if verbose != true
        cork.puts "Turning on --verbose"
        dm.verbose = true
      end

      cork.puts

      # We can use tokenless here, as it's running on someone's computer
      # and is IP locked, as opposed to on the CI.
      gh.support_tokenless_auth = true

      begin
        gh.fetch_details
      rescue Octokit::NotFound
        cork.puts "Local repository was not found on GitHub. If you're trying to test a private repository please provide a valid API token through " + "DANGER_GITHUB_API_TOKEN".yellow + " environment variable."
        return
      end

      dm.env.request_source = gh

      begin
        dm.env.fill_environment_vars
        dm.env.ensure_danger_branches_are_setup
        dm.env.scm.diff_for_folder(".", from: Danger::EnvironmentManager.danger_base_branch, to: Danger::EnvironmentManager.danger_head_branch)

        dm.parse(Pathname.new(@dangerfile_path))
        dm.print_results
      ensure
        dm.env.clean_up
      end
    end
  end
end
