module Danger
  class Runner < CLAide::Command
    require 'danger/commands/init'
    require 'danger/commands/local'
    require 'danger/commands/new_plugin'

    self.summary = 'Run the Dangerfile.'
    self.command = 'danger'
    self.version = Danger::VERSION

    self.plugin_prefixes = %w(claide danger)

    def initialize(argv)
      dangerfile = argv.option('dangerfile', 'Dangerfile')
      @dangerfile_path = dangerfile if File.exist? dangerfile
      @base = argv.option('base')
      @head = argv.option('head')
      @danger_id = argv.option('danger_id', 'danger')
      super
    end

    def validate!
      super
      if self.class == Runner && !@dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def self.options
      [
        ['--base=[master|dev|stable]', 'A branch/tag/commit to use as the base of the diff'],
        ['--head=[master|dev|stable]', 'A branch/tag/commit to use as the head'],
        ['--dangerfile=<path/to/dangerfile>', 'The location of your Dangerfile'],
        ['--danger_id=<id>', 'The identifier of this Danger instance']
      ].concat(super)
    end

    def run
      env = EnvironmentManager.new(ENV)
      dm = Dangerfile.new(env)

      if dm.env.pr?
        dm.verbose = verbose
        dm.init_plugins

        dm.env.fill_environment_vars

        begin
          dm.env.ensure_danger_branches_are_setup

          # Offer the chance for a user to specify a branch through the command line
          ci_base = @base || EnvironmentManager.danger_base_branch
          ci_head = @head || EnvironmentManager.danger_head_branch
          dm.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

          dm.parse Pathname.new(@dangerfile_path)

          post_results dm
          dm.print_results
        ensure
          dm.env.clean_up
        end
      else
        puts "Not a Pull Request - skipping `danger` run"
      end
    end

    def post_results(dm)
      gh = dm.env.request_source
      violations = dm.violation_report
      status = dm.status_report

      gh.update_pull_request!(warnings: violations[:warnings], errors: violations[:errors], messages: violations[:messages], markdowns: status[:markdowns], danger_id: @danger_id)
    end
  end
end
