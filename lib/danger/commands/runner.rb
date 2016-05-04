module Danger
  class Runner < CLAide::Command
    require 'danger/commands/init'
    require 'danger/commands/local'
    require 'danger/commands/new_plugin'

    self.summary = 'Run the Dangerfile.'
    self.command = 'danger'

    self.plugin_prefixes = %w(claide danger)

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      @base = argv.option('base')
      @head = argv.option('head')
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
        ['--head=[master|dev|stable]', 'A branch/tag/commit to use as the head']
      ].concat(super)
    end

    def run
      # The order of the following commands is *really* important
      dm = Dangerfile.new
      dm.verbose = verbose
      dm.env = EnvironmentManager.new(ENV)
      return unless dm.env.ci_source # if it's not a PR

      dm.env.fill_environment_vars
      dm.env.ensure_danger_branches_are_setup

      # Offer the chance for a user to specify a branch through the command line
      ci_base = @base || dm.env.danger_head_branch
      ci_head = @head || dm.env.danger_base_branch
      dm.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

      dm.parse Pathname.new(@dangerfile_path)

      post_results(dm)

      dm.env.clean_up

      dm.print_results
    end

    def post_results(dm)
      gh = dm.env.request_source
      gh.update_pull_request!(warnings: dm.warnings, errors: dm.errors, messages: dm.messages, markdowns: dm.markdowns)
    end
  end
end
