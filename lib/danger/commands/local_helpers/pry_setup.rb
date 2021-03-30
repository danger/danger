module Danger
  class PrySetup
    def initialize(cork)
      @cork = cork
    end

    def setup_pry(dangerfile_path, command)
      return dangerfile_path if dangerfile_path.empty?
      validate_pry_available(command)
      FileUtils.cp dangerfile_path, DANGERFILE_COPY
      File.open(DANGERFILE_COPY, "a") do |f|
        f.write("\nbinding.pry; File.delete(\"#{DANGERFILE_COPY}\")")
      end
      DANGERFILE_COPY
    end

    private

    attr_reader :cork

    DANGERFILE_COPY = "_Dangerfile.tmp".freeze

    def validate_pry_available(command)
      Kernel.require "pry"
    rescue LoadError
      cork.warn "Pry was not found, and is required for 'danger #{command} --pry'."
      cork.print_warnings
      abort
    end
  end
end
