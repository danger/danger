module Danger
  class Executor
    def initialize(system_env)
      @system_env = system_env
    end

    def run(env: nil,
            dm: nil,
            cork: nil,
            base: nil,
            head: nil,
            dangerfile_path: nil,
            danger_id: nil,
            fail_on_errors: nil)

      # Create a silent Cork instance if cork is nil, as it's like a test
      cork ||= Cork::Board.new(silent: false, verbose: false)

      #
      validate_ci
      return unless validate_pr

      # OK, then we can have some
      env ||= EnvironmentManager.new(@system_env, cork)
      dm ||= Dangerfile.new(env, cork)

      dm.init_plugins
      dm.env.fill_environment_vars

      begin
        dm.env.ensure_danger_branches_are_setup

        # Offer the chance for a user to specify a branch through the command line
        ci_base = base || EnvironmentManager.danger_base_branch
        ci_head = head || EnvironmentManager.danger_head_branch

        dm.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

        # Parse the local Dangerfile
        dm.parse(Pathname.new(dangerfile_path))

        post_results(dm, danger_id)
        dm.print_results
      ensure
        dm.env.clean_up
      end

      exit(1) if fail_on_errors && dm.failed?
    end

    def validate_ci
      # Could we find a CI source at all?
      unless EnvironmentManager.local_ci_source(@system_env)
        abort("Could not find the type of CI for Danger to run on.".red)
      end
    end

    def validate_pr?
    # Could we determine that the CI source is inside a PR?
      unless EnvironmentManager.pr?(@system_env)
        cork.puts "Not a Pull Request - skipping `danger` run".yellow
      end
      EnvironmentManager.pr?(@system_env)
    end

    def post_results(danger_file, danger_id)
      request_source = danger_file.env.request_source
      violations = danger_file.violation_report
      status = danger_file.status_report

      request_source.update_pull_request!(
        warnings: violations[:warnings],
        errors: violations[:errors],
        messages: violations[:messages],
        markdowns: status[:markdowns],
        danger_id: danger_id
      )
    end
  end
end
