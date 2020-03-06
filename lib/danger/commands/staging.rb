require "danger/commands/local_helpers/pry_setup"
require "fileutils"
require "tmpdir"

module Danger
  class Staging < Runner
    self.summary = "Run the Dangerfile locally against local master"
    self.command = "staging"

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

      env = EnvironmentManager.new(ENV, cork)
      dm = Dangerfile.new(env, cork)

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
end
