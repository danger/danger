# frozen_string_literal: true

require "danger/commands/local_helpers/http_cache"
require "danger/commands/local_helpers/pry_setup"
require "faraday/http_cache"
require "fileutils"
require "gitlab"
require "tmpdir"

module Danger
  class MR < Runner
    self.summary = "Run the Dangerfile locally against GitLab Merge Requests. Does not post to the MR. Usage: danger mr <URL>"
    self.command = "mr"

    def self.options
      [
        ["--clear-http-cache", "Clear the local http cache before running Danger locally."],
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."],
        ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"]
      ]
    end

    def initialize(argv)
      show_help = true if argv.arguments == ["-h"]

      @mr_url = argv.shift_argument
      @clear_http_cache = argv.flag?("clear-http-cache", false)
      dangerfile = argv.option("dangerfile", "Dangerfile")

      # Currently CLAide doesn't support short option like -h https://github.com/CocoaPods/CLAide/pull/60
      # when user pass in -h, mimic the behavior of passing in --help.
      argv = CLAide::ARGV.new ["--help"] if show_help

      super

      @dangerfile_path = dangerfile if File.exist?(dangerfile)

      if argv.flag?("pry", false)
        @dangerfile_path = PrySetup.new(cork).setup_pry(@dangerfile_path, MR.command)
      end
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
      unless @mr_url
        help! "Could not find a merge-request. Usage: danger mr <URL>"
      end
    end

    def run
      ENV["DANGER_USE_LOCAL_GIT"] = "YES"
      ENV["LOCAL_GIT_MR_URL"] = @mr_url if @mr_url

      configure_gitlab(ENV["DANGER_TMPDIR"] || Dir.tmpdir)

      env = EnvironmentManager.new(ENV, cork)
      dm = Dangerfile.new(env, cork)

      LocalSetup.new(dm, cork).setup(verbose: verbose) do
        dm.run(
          Danger::EnvironmentManager.danger_base_branch,
          Danger::EnvironmentManager.danger_head_branch,
          @dangerfile_path,
          nil,
          nil,
          nil,
          false
        )
      end
    end

    private

    def configure_gitlab(cache_dir)
      # setup caching for GitLab calls to avoid hitting the API rate limit too quickly
      cache_file = File.join(cache_dir, "danger_local_gitlab_cache")
      HTTPCache.new(cache_file, clear_cache: @clear_http_cache)

      # Configure GitLab client
      Gitlab.configure do |config|
        config.endpoint = ENV["DANGER_GITLAB_API_BASE_URL"] || ENV.fetch("CI_API_V4_URL", "https://gitlab.com/api/v4")
        config.private_token = ENV["DANGER_GITLAB_API_TOKEN"]
      end
    end
  end
end
