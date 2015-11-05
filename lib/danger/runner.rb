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
      dm = Dangerfile.new
      dm.env = EnvironmentManager.new(ENV)
      dm.env.fill_environment_vars
      dm.update_from_env
      dm.env.git.diff_for_folder(".")
      dm.parse Pathname.new(@dangerfile_path)

      if dm.failures
        puts "Uh Oh failed"
        exit(1)
      else
        puts "The Danger has passed. Phew."
      end
    end
  end
end
