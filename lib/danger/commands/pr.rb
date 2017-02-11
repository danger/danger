require "danger/commands/local_helpers/http_cache"
require "faraday/http_cache"
require "fileutils"
require "octokit"
require "tmpdir"

module Danger
  class PR < Runner
    self.summary = "Run the Dangerfile against Pull Requests (works with forks, too).".freeze
    self.command = "pr".freeze

    def self.options
      [
        ["--clear-http-cache", "Clear the local http cache before running Danger locally."],
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."],
        ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"]
      ]
    end

    def initialize(argv)
      @pr_url = argv.shift_argument
      @clear_http_cache = argv.flag?("clear-http-cache", false)
      dangerfile = argv.option("dangerfile", "Dangerfile")

      super

      @dangerfile_path = dangerfile if File.exist?(dangerfile)

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
      cork.warn "Pry was not found, and is required for 'danger pr --pry'."
      cork.print_warnings
      abort
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def run
      ENV["DANGER_USE_LOCAL_GIT"] = "YES"
      ENV["LOCAL_GIT_PR_URL"] = @pr_url if @pr_url

      configure_octokit(ENV["DANGER_TMPDIR"] || Dir.tmpdir)

      env = EnvironmentManager.new(ENV, cork)
      dm = Dangerfile.new(env, cork)

      LocalSetup.new(dm, cork).setup(verbose: verbose) do
        dm.run(
          Danger::EnvironmentManager.danger_base_branch,
          Danger::EnvironmentManager.danger_head_branch,
          @dangerfile_path,
          nil,
          nil
        )
      end
    end

    private

    def configure_octokit(cache_dir)
      # setup caching for Github calls to hitting the API rate limit too quickly
      cache_file = File.join(cache_dir, "danger_local_cache")
      cache = HTTPCache.new(cache_file, clear_cache: @clear_http_cache)
      Octokit.middleware = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, store: cache, serializer: Marshal, shared_cache: false
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
