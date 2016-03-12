module Danger
  class Runner < CLAide::Command
    require 'danger/commands/init'
    require 'danger/commands/local'

    self.summary = 'Run the Dangerfile.'
    self.command = 'danger'

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

      gh = dm.env.request_source
      ci = dm.env.ci_source

      # Offer the chance for a user to specify a branch
      # then the ci service, then finally fall back to github
      # GH-based sha diffs can be unreliable, see #88

      ci_base = @base || ci.base_ref || gh.base_ref
      ci_head = @head || ci.head_ref || gh.head_ref

      dm.env.scm.diff_for_folder(".", from: ci_base, to: ci_head)

      dm.parse Pathname.new(@dangerfile_path)

      post_results(dm)
    end

    def post_results(dm)
      gh = dm.env.request_source
      gh.update_pull_request!(warnings: dm.warnings, errors: dm.errors, messages: dm.messages)
    end
  end
end
