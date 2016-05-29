module Danger
  class Plugin
    def initialize(dangerfile)
      @dangerfile = dangerfile
    end

    def self.instance_name
      self.to_s.gsub("Danger", "").danger_underscore.split('/').last
    end

    # Since we have a reference to the Dangerfile containing all the information
    # We need to redirect the self calls to the Dangerfile
    def method_missing(method_sym, *arguments, &_block)
      @dangerfile.send(method_sym, *arguments)
    end
  end
end
