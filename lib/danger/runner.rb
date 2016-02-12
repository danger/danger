module Danger
  class Runner < CLAide::Command
    self.description = 'Run the Dangerfile.'
    self.command = 'danger'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      @base = argv.option('base')
      @head = argv.option('head')
      @circle_token = argv.option('circle-ci-token')
      super
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def self.options
      [
        ['--base=[master|dev|stable]', 'A branch/tag/commit to use as the base of the diff'],
        ['--head=[master|dev|stable]', 'A branch/tag/commit to use as the head'],
        ['--circle-ci-token=[token]', 'A Circle CI API token to be used if needed']
      ].concat(super)
    end

    def run
      # The order of the following commands is *really* important
      dm = Dangerfile.new
      ENV["CIRCLE_CI_API_TOKEN"] = @circle_token unless @circle_token.nil?
      dm.env = EnvironmentManager.new(ENV)
      return unless dm.env.ci_source # if it's not a PR
      dm.env.fill_environment_vars

      gh = dm.env.request_source
      ci_base = @base || gh.base_commit
      ci_head = @head || gh.head_commit

      dm.env.scm.diff_for_folder(".", ci_base, ci_head)
      dm.parse Pathname.new(@dangerfile_path)

      post_results(dm)
    end

    def post_results(dm)
      gh = dm.env.request_source
      gh.update_pull_request!(warnings: dm.warnings, errors: dm.errors, messages: dm.messages)
    end
  end
end
