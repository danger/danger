require "danger/commands/local_helpers/http_cache"
require "danger/commands/local_helpers/pry_setup"
require "faraday/http_cache"
require "fileutils"
require "octokit"
require "tmpdir"
require "no_proxy_fix"

module Danger
  class PR < Runner
    self.summary = "Run the Dangerfile locally against Pull Requests (works with forks, too). Does not post to the PR. Usage: danger pr <URL>".freeze
    self.command = "pr".freeze

    def self.options
      [
        ["--clear-http-cache", "Clear the local http cache before running Danger locally."],
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."],
        ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"],
        ["--verify-ssl", "Verify SSL in Octokit"]
      ]
    end

    def initialize(argv)
      show_help = true if argv.arguments == ["-h"]

      @pr_url = argv.shift_argument
      @clear_http_cache = argv.flag?("clear-http-cache", false)
      dangerfile = argv.option("dangerfile", "Dangerfile")
      @verify_ssl = argv.flag?("verify-ssl", true)

      # Currently CLAide doesn't support short option like -h https://github.com/CocoaPods/CLAide/pull/60
      # when user pass in -h, mimic the behavior of passing in --help.
      argv = CLAide::ARGV.new ["--help"] if show_help

      super

      @dangerfile_path = dangerfile if File.exist?(dangerfile)

      if argv.flag?("pry", false)
        @dangerfile_path = PrySetup.new(cork).setup_pry(@dangerfile_path)
      end
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
      unless @pr_url
        help! "Could not find a pull-request. Usage: danger pr <URL>"
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
      Octokit.configure do |config|
        config.connection_options[:ssl] = { verify: @verify_ssl }
      end
      Octokit.middleware = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, store: cache, serializer: Marshal, shared_cache: false
        builder.use Octokit::Middleware::FollowRedirects
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
