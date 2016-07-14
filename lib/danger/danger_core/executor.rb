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
      env ||= EnvironmentManager.new(ENV)
      dm ||= Dangerfile.new(env, cork)

      if dm.env.pr?
        dm.init_plugins

        dm.env.fill_environment_vars

        begin
          dm.env.ensure_danger_branches_are_setup

          # Offer the chance for a user to specify a branch through the command line
          ci_base = base || EnvironmentManager.danger_base_branch
          ci_head = head || EnvironmentManager.danger_head_branch
          dm.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

          dm.parse(Pathname.new(dangerfile_path))

          if dm.env.request_source.organisation && (danger_repo = dm.env.request_source.fetch_danger_repo)
            url = dm.env.request_source.file_url(repository: danger_repo.name, path: "Dangerfile")
            path = dm.plugin.download(url)
            dm.parse(Pathname.new(path))
          end

          post_results(dm, danger_id)
          dm.print_results
        ensure
          dm.env.clean_up
        end
      else
        cork.puts "Not a Pull Request - skipping `danger` run"
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
