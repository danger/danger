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
            fail_if_no_pr: nil,
            remove_previous_comments: nil)
      # Create a silent Cork instance if cork is nil, as it's likely a test
      cork ||= Cork::Board.new(silent: false, verbose: false)

      # Run some validations
      validate!(cork, fail_if_no_pr: fail_if_no_pr)

      # OK, we now know that Danger can run in this environment
      env ||= EnvironmentManager.new(system_env, cork, danger_id)
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

    def validate!(cork, fail_if_no_pr: false)
      validate_ci!
      validate_pr!(cork, fail_if_no_pr)
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
    def validate_pr!(cork, fail_if_no_pr)
      unless EnvironmentManager.pr?(system_env)
        ci_name = EnvironmentManager.local_ci_source(system_env).name.split("::").last

        msg = "Not a #{ci_name} #{commit_request(ci_name)} - skipping `danger` run. "
        # circle won't run danger properly if the commit is pushed and build runs before the PR exists
        # https://danger.systems/guides/troubleshooting.html#circle-ci-doesnt-run-my-build-consistently
        # the best solution is to enable `fail_if_no_pr`, and then re-run the job once the PR is up
        if ci_name == "CircleCI"
          msg << "If you only created the PR recently, try re-running your workflow."
        end
        cork.puts msg.strip.yellow

        exit(fail_if_no_pr ? 1 : 0)
      end
    end

    def base_branch(user_specified_base_branch)
      user_specified_base_branch || EnvironmentManager.danger_base_branch
    end

    def head_branch(user_specified_head_branch)
      user_specified_head_branch || EnvironmentManager.danger_head_branch
    end

    def commit_request(ci_name)
      return "Merge Request" if ci_name == 'GitLabCI'
      return "Pull Request"
    end
  end
end
