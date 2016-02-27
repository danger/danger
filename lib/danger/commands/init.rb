module Danger
  class Init < Runner
    self.summary = 'Helps you set up Danger.'
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
      write_template_to_current_dir
      puts "Successfully created 'Dangerfile'"
    end

    def write_template_to_current_dir
      dir = Danger.gem_path
      content = File.read(File.join(dir, "lib", "assets", "DangerfileTemplate"))
      File.write("Dangerfile", content)
    end
  end
end
