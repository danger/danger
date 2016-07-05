require 'json'

#
#
#   So you want to improve this? Great. Hard thing is getting yourself into a position where you
#   have access to all the tokens, so here's something you should run in `bundle exec pry` to dig in:
#
#       require 'danger'
#       require 'yard'
#       parser = Danger::PluginParser.new "spec/fixtures/plugins/example_fully_documented.rb"
#       parser.parse
#       plugins = parser.plugins_from_classes(parser.classes_in_file)
#       git = plugins.first
#       klass = git
#       parser.to_dict(plugins)
#
#   Then some helpers
#
#       attribute_meths = klass.attributes[:instance].values.map(&:values).flatten
#
#       methods = klass.meths - klass.inherited_meths - attribute_meths
#       usable_methods = methods.select { |m| m.visibility == :public }.reject { |m| m.name == :initialize }
#
#
#   the alternative, is to add
#
#       require 'pry'
#       binding.pry
#
#   anywhere inside the source code below.
#

module Danger
  class PluginParser
    attr_accessor :registry

    def initialize(paths)
      raise "Path cannot be empty" if paths.empty?

      if paths.kind_of? String
        @paths = [File.expand_path(paths)]
      else
        @paths = paths
      end
    end

    def parse
      require 'yard'
      # could this go in a singleton-y place instead?
      # like class initialize?
      YARD::Tags::Library.define_tag('tags', :tags)
      YARD::Tags::Library.define_tag('availablity', :availablity)
      files = ["lib/danger/plugin_support/plugin.rb"] + @paths

      # This turns on YARD debugging
      # $DEBUG = true

      self.registry = YARD::Registry.load(files, true)
    end

    def classes_in_file
      registry.all(:class).select { |klass| @paths.include? klass.file }
    end

    def plugins_from_classes(classes)
      classes.select { |klass| klass.inheritance_tree.map(&:name).include? :Plugin }
    end

    def to_json
      plugins = plugins_from_classes(classes_in_file)
      to_dict(plugins).to_json
    end

    # rubocop:disable Metrics/AbcSize
    def to_dict(classes)
      d_meth = lambda do |meth|
        return nil if meth.nil?
        {
          name: meth.name,
          body_md: meth.docstring,
          params: meth.parameters,
          tags: meth.tags.map do |t|
            {
               name: t.tag_name,
               types: t.types
            }
          end
        }
      end

      d_attr = lambda do |attribute|
        {
          read: d_meth.call(attribute[:read]),
          write: d_meth.call(attribute[:write])
        }
      end

      classes.map do |klass|
        # Adds the class being parsed into the ruby runtime, so that we can access it's instance_name
        require klass.file
        real_klass = Danger.const_get klass.name
        attribute_meths = klass.attributes[:instance].values.map(&:values).flatten

        methods = klass.meths - klass.inherited_meths - attribute_meths
        usable_methods = methods.select { |m| m.visibility == :public }.reject { |m| m.name == :initialize || m.name == :insance_name }

        {
          name: klass.name.to_s,
          body_md: klass.docstring,
          instance_name: real_klass.instance_name,
          example_code: klass.tags.select { |t| t.tag_name == "example" }.map { |tag| { title: tag.name, text: tag.text } }.compact,
          attributes: klass.attributes[:instance].map do |pair|
            { pair.first => d_attr.call(pair.last) }
          end,
          methods: usable_methods.map { |m| d_meth.call(m) },
          tags: klass.tags.select { |t| t.tag_name == "tags" }.map(&:text).compact,
          see: klass.tags.select { |t| t.tag_name == "see" }.map(&:name).map(&:split).flatten.compact,
          file: klass.file.gsub(File.expand_path("."), "")
        }
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
