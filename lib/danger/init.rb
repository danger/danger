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
      gem_name = "danger"
      unless Gem::Specification.find_all_by_name(gem_name).any?
        raise "Couldn't find gem directory for 'danger'"
      end

      dir = Gem::Specification.find_by_name(gem_name).gem_dir
      content = File.read(File.join(dir, "lib", "assets", "DangerfileTemplate"))
      File.write("Dangerfile", content)
      puts "Successfully created 'Dangerfile'"
    end
  end
end
