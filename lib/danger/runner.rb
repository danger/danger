module Danger
  class Runner < CLAide::Command
    self.description = 'Run the Dangerfile.'
    self.command = 'danger'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def run
      # The order of the following commands is *really* important
      dm = Dangerfile.new
      dm.env = EnvironmentManager.new(ENV)
      dm.env.fill_environment_vars
      dm.env.git.diff_for_folder(".")
      dm.update_from_env
      dm.parse Pathname.new(@dangerfile_path)

      post_results(dm)
    end

    def post_results(dm)
      gh = dm.env.github
      comment_url = gh.submit_comment!(warnings: dm.warnings, errors: dm.errors)
      gh.submit_pull_request_status!(warnings: dm.warnings, errors: dm.errors, details_url: comment_url)
    end
  end
end
