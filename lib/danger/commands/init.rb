require 'danger/commands/init_helpers/interviewer'

module Danger
  class Init < Runner
    self.summary = 'Helps you set up Danger.'
    self.command = 'init'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end

    def validate!
      # if @dangerfile_path
      #   help! "Found an existing Dangerfile."
      # end
    end

    def run
      ui = Interviewer.new
      ui.say "\nOK, thanks #{ENV["LOGNAME"]}, grab a seat and we'll get you started.\n".yellow
      ui.pause 1

      show_todo_state
      ui.pause 1.4



      # write_template_to_current_dir
      puts "Successfully created 'Dangerfile'"
    end

    def ui
      @ui ||= Interviewer.new
    end

    def show_todo_state
      ui.say "We need to do the following steps:\n"
      ui.pause 0.6
      ui.say " - [ ] Create a GitHub account for Danger use for messaging."
      ui.pause 0.6
      ui.say " - [ ] Set up an access token for Danger."
      ui.pause 0.6
      ui.say " - [ ] Create a Dangerfile and add a few simple rules."
      ui.pause 0.6
      ui.say " - [ ] Set up Danger to run on your CI.\n\n"
    end

    def write_template_to_current_dir
      dir = Danger.gem_path
      content = File.read(File.join(dir, "lib", "assets", "DangerfileTemplate"))
      File.write("Dangerfile", content)
    end
  end
end
