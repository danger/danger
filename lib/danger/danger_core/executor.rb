module Danger
  class Executor
    def run(env: nil,
            dm: nil,
            cork: nil,
            base: nil,
            head: nil,
            dangerfile_path: nil,
            danger_id: nil)

      cork ||= Cork::Board.new(silent: false,
                              verbose: false)

      # Could we find a CI source at all?
      unless EnvironmentManager.local_ci_source(ENV)
        abort("Could not find the type of CI for Danger to run on.".red) unless ci_klass
      end

      # Could we determine that the CI source is inside a PR?
      unless EnvironmentManager.pr?(ENV)
        cork.puts "Not a Pull Request - skipping `danger` run".yellow
        return
      end

      # OK, then we can set ourselves up
      env ||= EnvironmentManager.new(ENV)
      dm ||= Dangerfile.new(env, cork)

      env.fill_environment_vars

      begin
        env.ensure_danger_branches_are_setup

        # Offer the chance for a user to specify a branch through the command line
        ci_base = base || EnvironmentManager.danger_base_branch
        ci_head = head || EnvironmentManager.danger_head_branch
        env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

        dm.parse(Pathname.new(dangerfile_path))

        if dm.env.request_source.organisation && !dm.env.request_source.danger_repo? && (danger_repo = dm.env.request_source.fetch_danger_repo)
          url = dm.env.request_source.file_url(repository: danger_repo.name, path: "Dangerfile")
          path = dm.plugin.download(url)
          dm.parse(Pathname.new(path))
        end

        post_results(dm, danger_id)
        dm.print_results
      ensure
        dm.env.clean_up
      end
    end

    def post_results(dm, danger_id)
      gh = dm.env.request_source
      violations = dm.violation_report
      status = dm.status_report

      gh.update_pull_request!(warnings: violations[:warnings], errors: violations[:errors], messages: violations[:messages], markdowns: status[:markdowns], danger_id: danger_id)
    end
  end
end
