require "danger/commands/local_helpers/pry_setup"
require "fileutils"

module Danger
  class DryRun < Runner
    self.summary = "Dry-Run the Dangerfile locally, so you could check some violations before sending real PR/MR."
    self.command = "dry_run"

    def self.options
      [
        ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
      ]
    end

    def initialize(argv)
      show_help = true if argv.arguments == ["-h"]

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
      ENV["DANGER_USE_LOCAL_ONLY_GIT"] = "YES"
      ENV["DANGER_LOCAL_HEAD"] = @head if @head
      ENV["DANGER_LOCAL_BASE"] = @base if @base

      env = EnvironmentManager.new(ENV, cork)
      dm = Dangerfile.new(env, cork)

      exit 1 if dm.run(
        Danger::EnvironmentManager.danger_base_branch,
        Danger::EnvironmentManager.danger_head_branch,
        @dangerfile_path,
        nil,
        nil,
        nil
      )
    end
  end
end
