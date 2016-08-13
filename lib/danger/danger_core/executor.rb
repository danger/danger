require "danger/danger_core/plugin_printer"
require "danger/danger_core/dangerfile_printer"

module Danger
  class Executor
    def run(env: nil,
            dm: nil,
            cork: nil,
            base: nil,
            head: nil,
            dangerfile_path: nil,
            danger_id: nil,
            verbose: false)

      cork ||= Cork::Board.new(silent: false, verbose: false)
      dangerfile_path ||= path_for_implicit_dangerfile

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
      dm ||= dangerfile_for_path(path, env, cork)

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
        print_results(env, cork) if verbose
      ensure
        dm.env.clean_up
      end
    end

    # Determines the Dangerfile based on the current folder structure
    def path_for_implicit_dangerfile
      ["Dangerfile", "Dangerfile.rb", "Dangerfile.js"].each do |file|
        return file if File.exist? file
      end
      abort("Could not find a Dangerfile to run.".red)
    end

    # Gives you either a Dangerfile for Ruby, or a JS version
    def dangerfile_for_path(path, env, cork)
      klass = path.end_with?("js") ? DangerfileJS : Dangerfile
      klass.new(env, cork)
    end

    # Prints out all the useful metadata
    def print_results(env, cork)
      # Print out the table of plugin metadata
      plugin_printer = PluginPrinter.new(env.plugin_host)
      plugin_printer.print_plugin_metadata(env, cork)

      # Print out the results from the Dangerfile
      messaging = env.plugin_host.external_plugins.first { |plugin| plugin.is_kind? DangerfileMessagingPlugin }
      printer = DangerfilePrinter.new(messaging, cork)
      printer.print_results
    end

    def post_results(dm, danger_id)
      gh = dm.env.request_source
      violations = dm.violation_report
      status = dm.status_report

      gh.update_pull_request!(warnings: violations[:warnings], errors: violations[:errors], messages: violations[:messages], markdowns: status[:markdowns], danger_id: danger_id)
    end
  end
end
