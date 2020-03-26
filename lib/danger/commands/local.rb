require "danger/commands/local_helpers/http_cache"
require "danger/commands/local_helpers/local_setup"
require "danger/commands/local_helpers/pry_setup"
require "faraday/http_cache"
require "fileutils"
require "octokit"
require "tmpdir"

module Danger
  class Local < Runner
    self.summary = "Run the Dangerfile locally. This command is generally deprecated in favor of `danger pr`."
    self.command = "local"

    def self.options
      [
        ["--use-merged-pr=[#id]", "The ID of an already merged PR inside your history to use as a reference for the local run."],
        ["--clear-http-cache", "Clear the local http cache before running Danger locally."],
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
      ]
    end

    def initialize(argv)
      show_help = true if argv.arguments == ["-h"]

      @pr_num = argv.option("use-merged-pr")
      @clear_http_cache = argv.flag?("clear-http-cache", false)

      # Currently CLAide doesn't support short option like -h https://github.com/CocoaPods/CLAide/pull/60
      # when user pass in -h, mimic the behavior of passing in --help.
      argv = CLAide::ARGV.new ["--help"] if show_help

      super

      if argv.flag?("pry", false)
        @dangerfile_path = PrySetup.new(cork).setup_pry(@dangerfile_path)
      end
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

      configure_octokit(ENV["DANGER_TMPDIR"] || Dir.tmpdir)

      env = EnvironmentManager.new(ENV, cork)
      dm = Dangerfile.new(env, cork)

      LocalSetup.new(dm, cork).setup(verbose: verbose) do
        dm.run(
          Danger::EnvironmentManager.danger_base_branch,
          Danger::EnvironmentManager.danger_head_branch,
          @dangerfile_path,
          nil,
          nil,
          nil
        )
      end
    end

    private

    # this method is a duplicate of Commands::PR#configure_octokit
    # - worth a refactor sometime?
    def configure_octokit(cache_dir)
      # setup caching for Github calls to hitting the API rate limit too quickly
      cache_file = File.join(cache_dir, "danger_local_cache")
      cache = HTTPCache.new(cache_file, clear_cache: @clear_http_cache)
      Octokit.middleware = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, store: cache, serializer: Marshal, shared_cache: false
        builder.use Octokit::Middleware::FollowRedirects
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
