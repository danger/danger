module Danger
  class Plugin
    def initialize(dangerfile)
      @dangerfile = dangerfile
    end

    def self.instance_name
      self.to_s.gsub("Danger", "").danger_underscore.split('/').last
    end

    # Both of these methods exist on all objects
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-warn
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-fail
    # However, as we're using using them in the DSL, they won't
    # get method_missing called.

    def warn(message)
      puts "Danger warn"
      @dangerfile.warn(message)
    end

    def fail(message)
      puts "Danger fail"
      @dangerfile.fail(message)
    end

    # Since we have a reference to the Dangerfile containing all the information
    # We need to redirect the self calls to the Dangerfile
    def method_missing(method_sym, *arguments, &_block)
      @dangerfile.send(method_sym, *arguments)
    end
  end
end
