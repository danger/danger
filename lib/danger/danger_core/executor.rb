module Danger
  class Executor
    def initialize(system_env)
      @system_env = system_env

      # Run some validations
      validate!
    end

    def run(env: nil,
            dm: nil,
            cork: nil,
            base: nil,
            head: nil,
            dangerfile_path: nil,
            danger_id: nil,
            fail_on_errors: nil)
      # Create a silent Cork instance if cork is nil, as it's likely a test
      cork ||= Cork::Board.new(silent: false, verbose: false)

      # OK, we now know that Danger can run in this enviroment
      env ||= EnvironmentManager.new(system_env, cork)
      dm ||= Dangerfile.new(env, cork)

      # Setup internal state
      dm.init_plugins
      dm.env.fill_environment_vars

      begin
        # Sets up the git environment
        setup_for_running dm, base, head
        # Parse the local Dangerfile
        dm.parse Pathname.new(dangerfile_path)

        # Push results to the API
        # Pass along the details of the run to the request source
        # to send back to the code review site.
        dm.post_results(danger_id)

        # Print results in the terminal
        dm.print_results
      ensure

        # Makes sure that Danger specific git branches are cleaned
        dm.env.clean_up
      end

      # By default Danger will use the status API to fail a build,
      # allowing execution to continue, this behavior isn't always
      # optimal for everyone.
      exit(1) if fail_on_errors && dm.failed?
    end

    # Sets up, and runs the git environment for the diff,
    # and offers the chance for a user to specify custom branches
    # through the command line
    def setup_for_running(dangerfile, base, head)
      dangerfile.env.ensure_danger_branches_are_setup

      ci_base = base || EnvironmentManager.danger_base_branch
      ci_head = head || EnvironmentManager.danger_head_branch

      dangerfile.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)
    end

    def validate!
      validate_ci!
      validate_pr!
    end

    private

    attr_reader :system_env

    # Could we find a CI source at all?
    def validate_ci!
      unless EnvironmentManager.local_ci_source(system_env)
        abort("Could not find the type of CI for Danger to run on.".red)
      end
    end

    # Could we determine that the CI source is inside a PR?
    def validate_pr!
      unless EnvironmentManager.pr?(system_env)
        abort("Not a Pull Request - skipping `danger` run".yellow)
      end
    end
  end
end
