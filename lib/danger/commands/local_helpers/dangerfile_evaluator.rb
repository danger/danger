module Danger
  class DangerfileLocalEvaluator
    def initialize(dm, dangerfile_path)
      @dangerfile_path = dangerfile_path
      @dm = dm
    end

    def evaluate
      begin
        @dm.env.fill_environment_vars
        @dm.env.ensure_danger_branches_are_setup
        @dm.env.scm.diff_for_folder(".", from: Danger::EnvironmentManager.danger_base_branch, to: Danger::EnvironmentManager.danger_head_branch)

        @dm.parse(@dangerfile_path)
        @dm.print_results
      ensure
        @dm.env.clean_up
      end
    end
  end
end
