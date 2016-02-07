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
      dir = Danger.gem_path

      content = File.read(File.join(dir, "lib", "assets", "DangerfileTemplate"))
      File.write("Dangerfile", content)
      puts "Successfully created 'Dangerfile'"
    end
  end
end
