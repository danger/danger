require 'json'

=begin

  So you want to improve this? Great. Hard thing is getting yourself into a position where you
  have access to all the tokens, so here's something you should run in `bundle exec pry` to dig in:

      require 'danger'
      require 'yard'
      parser = Danger::PluginParser.new "spec/fixtures/plugins/example_fully_documented.rb"
      parser.parse
      plugins = parser.plugins_from_classes(parser.classes_in_file)
      git = plugins.first
      klass = git
      parser.to_dict(plugins)

  Then some helpers

      attribute_meths = klass.attributes[:instance].values.map(&:values).flatten

      methods = klass.meths - klass.inherited_meths - attribute_meths
      usable_methods = methods.select { |m| m.visibility == :public }.reject { |m| m.name == :initialize }

  the alternative, is to add

      require 'pry'
      binding.pry

  anywhere inside the source code below.

=end

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

    def method_return_string(meth)
      return "" unless meth[:tags]

      return_value = meth[:tags].find { |t| t[:name] == "return" && t[:types] }
      return "" if return_value.nil?
      return "" if return_value[:types].nil?
      return "" unless return_value[:types].kind_of? Array

      unless return_value.empty?
        return "" if return_value[:types].first == "void"
        return return_value[:types].first
      end
      ""
    end

    def method_params(params)
      return {} unless params[:params]

      params_names = params[:params].compact.flat_map(&:first)
      params_values = params[:tags].find { |t| t[:name] == "param" }

      return {} if params_values.nil?
      return {} if params_values[:types].nil?

      return params_names.map.with_index do |name, index|
        { name => params_values[:types][index] }
      end
    end

    def method_parser(meth)
      return nil if meth.nil?
      method = {
        name: meth.name,
        body_md: meth.docstring,
        params: meth.parameters,
        tags: meth.tags.map { |t| { name: t.tag_name, types: t.types } }
      }
      method[:param_couplets] = method_params(method)
      method
    end

    def attribute_parser(attribute)
      {
        read: method_parser(attribute[:read]),
        write: method_parser(attribute[:write])
      }
    end

    def to_dict(classes)
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
          attributes: klass.attributes[:instance].map { |pair| { pair.first => attribute_parser(pair.last) } },
          methods: usable_methods.map { |m| method_parser(m) },
          tags: klass.tags.select { |t| t.tag_name == "tags" }.map(&:text).compact,
          see: klass.tags.select { |t| t.tag_name == "see" }.map(&:name).map(&:split).flatten.compact,
          file: klass.file.gsub(File.expand_path("."), "")
        }
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
