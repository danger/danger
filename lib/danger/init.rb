module Danger
  class Init < Danger::Runner
    self.description = 'Creates a Dangerfile.'
    self.command = 'init'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end

    def validate!
      if @dangerfile_path
        help! "Found an existing Dangerfile."
      end
    end

    def run
      example_content = 'warn("PR is classed as Work in Progress") if pr_title.include? "[WIP]"'
      File.write("Dangerfile", example_content)
      puts "Successfully created 'Dangerfile'"
    end
  end
end
