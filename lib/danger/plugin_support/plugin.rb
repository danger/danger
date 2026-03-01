module Danger
  class Plugin
    def initialize(dangerfile)
      @dangerfile = dangerfile
    end

    def self.instance_name
      to_s.gsub("Danger", "").danger_underscore.split("/").last
    end

    # Both of these methods exist on all objects
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-warn
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-fail
    # However, as we're using using them in the DSL, they won't
    # get method_missing called correctly.
    undef :warn, :fail

    # Since we have a reference to the Dangerfile containing all the information
    # We need to redirect the self calls to the Dangerfile

    # rubocop:disable Style/MethodMissing
    def method_missing(method_sym, *arguments, &block)
      @dangerfile.send(method_sym, *arguments, &block)
    end

    def self.all_plugins
      @all_plugins ||= []
    end

    def self.clear_external_plugins
      @all_plugins = @all_plugins.select { |plugin| Dangerfile.essential_plugin_classes.include? plugin }
    end

    def self.inherited(plugin)
      Plugin.all_plugins.push(plugin)
    end

    private

    # When using `danger local --pry`, every plugin had an unreasonable
    # amount of text output due to the Dangerfile reference in every
    # plugin. So, it is filtered out. Users will start out in the context
    # of the Dangerfile, and can view it by just typing `self` into the REPL.
    #
    def pretty_print_instance_variables
      super - [:@dangerfile]
    end
  end
end
