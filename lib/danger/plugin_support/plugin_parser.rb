require "json"

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

    def initialize(paths, verbose = false)
      raise "Path cannot be empty" if paths.empty?

      setup_yard(verbose)

      if paths.kind_of? String
        @paths = [File.expand_path(paths)]
      else
        @paths = paths
      end
    end

    def setup_yard(verbose)
      require 'yard'

      # Unless specifically asked, don't output anything.
      unless verbose
        YARD::Logger.instance.level = YARD::Logger::FATAL
      end

      # Add some of our custom tags
      YARD::Tags::Library.define_tag('tags', :tags)
      YARD::Tags::Library.define_tag('availablity', :availablity)
    end

    def parse
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
      to_h(plugins)
    end

    def to_json_string
      plugins = plugins_from_classes(classes_in_file)
      to_h(plugins).to_json
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

    def method_params(method)
      return {} unless method[:params]

      params_names = method[:params].map { |param| param.compact.join("=").strip }
      params_values = method[:tags].select { |t| t[:name] == "param" }

      return {} if params_values.empty?
      return {} if params_values.select { |p| p[:types] }.empty?

      return params_names.map.with_index do |name, index|
        name = name.delete ":"
        if index < params_values.length
          type = params_values[index][:types]
          { name => type ? type.first : "Unknown" }
        else
          { name => "Unknown" }
        end
      end
    end

    def method_parser(gem_path, meth)
      return nil if meth.nil?
      method = {
        name: meth.name,
        body_md: meth.docstring,
        params: meth.parameters,
        files: meth.files.map { |item| [item.first.gsub(gem_path, ""), item.last] },
        tags: meth.tags.map { |t| { name: t.tag_name, types: t.types } }
      }


      return_v = method_return_string(method)
      params_v = method_params(method)

      # Pull out some derived data
      method[:param_couplets] = params_v
      method[:return] = return_v

      # Create the center params, `thing: OK, other: Thing`
      string_params = params_v.map do |param|
        name = param.keys.first
        param[name].nil? ? name : name + ": " + param[name]
      end.join ", "

      # Wrap it in () if there _are_ params
      string_params = "(" + string_params + ")" unless string_params.empty?
      # Append the return type if we have one
      suffix = return_v.empty? ? "" : " -> #{return_v}"

      method[:one_liner] = meth.name.to_s + string_params + suffix
      method
    end

    def attribute_parser(gem_path, attribute)
      {
        read: method_parser(gem_path, attribute[:read]),
        write: method_parser(gem_path, attribute[:write])
      }
    end

    def to_h(classes)
      classes.map do |klass|
        # Adds the class being parsed into the ruby runtime, so that we can access it's instance_name
        require klass.file
        real_klass = Danger.const_get klass.name
        attribute_meths = klass.attributes[:instance].values.map(&:values).flatten

        methods = klass.meths - klass.inherited_meths - attribute_meths
        usable_methods = methods.select { |m| m.visibility == :public }.reject { |m| m.name == :initialize || m.name == :instance_name || m.name == :new }

        plugin_gem = klass.file.include?("gems") ? klass.file.split("gems/").last.split("-")[0..-2].join("-") : nil
        # Pull out the gem's path ( to make relative file paths )
        # if no gem is found, index  = 0, making gem_path = ""
        index_of_gem_in_path = plugin_gem ? klass.file.split("/").index { |component| component.include? plugin_gem } : 0
        gem_path = klass.file.split("/")[0..index_of_gem_in_path].join("/")

        {
          name: klass.name.to_s,
          body_md: klass.docstring,
          instance_name: real_klass.instance_name,
          gem: plugin_gem,
          gem_path: gem_path,
          files: klass.files.map { |item| [item.first.gsub(gem_path, ""), item.last] },
          example_code: klass.tags.select { |t| t.tag_name == "example" }.map { |tag| { title: tag.name, text: tag.text } }.compact,
          attributes: klass.attributes[:instance].map { |pair| { pair.first => attribute_parser(gem_path, pair.last) } },
          methods: usable_methods.map { |m| method_parser(gem_path, m) },
          tags: klass.tags.select { |t| t.tag_name == "tags" }.map(&:text).compact,
          see: klass.tags.select { |t| t.tag_name == "see" }.map(&:name).map(&:split).flatten.compact,
        }
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
