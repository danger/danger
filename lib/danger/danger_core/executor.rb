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
            new_comment: nil,
            fail_on_errors: nil,
            remove_previous_comments: nil)
      # Create a silent Cork instance if cork is nil, as it's likely a test
      cork ||= Cork::Board.new(silent: false, verbose: false)

      # Run some validations
      validate!(cork)

      # OK, we now know that Danger can run in this enviroment
      env ||= EnvironmentManager.new(system_env, cork)
      dm ||= Dangerfile.new(env, cork)

      ran_status = begin
        dm.run(
          base_branch(base),
          head_branch(head),
          dangerfile_path,
          danger_id,
          new_comment,
          remove_previous_comments
        )
      end

      # By default Danger will use the status API to fail a build,
      # allowing execution to continue, this behavior isn't always
      # optimal for everyone.
      exit(1) if fail_on_errors && ran_status
    end

    def validate!(cork)
      validate_ci!
      validate_pr!(cork)
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
    def validate_pr!(cork)
      unless EnvironmentManager.pr?(system_env)
        ci_name = EnvironmentManager.local_ci_source(system_env).name.split("::").last
        cork.puts "Not a #{ci_name} Pull Request - skipping `danger` run".yellow
        exit(0)
      end
    end

    def base_branch(user_specified_base_branch)
      user_specified_base_branch || EnvironmentManager.danger_base_branch
    end

    def head_branch(user_specified_head_branch)
      user_specified_head_branch || EnvironmentManager.danger_head_branch
    end
  end
end
