module Danger
  class PluginLinter
    class Rule
      attr_accessor :modifier, :description, :title, :function, :ref, :metadata

      def initialize(modifier, ref, title, description, function)
        @modifier = modifier
        @title = title
        @description = description
        @function = function
        @ref = ref
      end

      def object_applied_to
        metadata[:name]
      end
    end

    attr_accessor :json, :warnings, :errors

    def initialize(json)
      @json = json
      @warnings = []
      @errors = []
    end

    def class_rules
      [
        Rule.new(:error, 4..6, "Description Markdown", "Above your class you need documentation that covers the scope, and the usage of your plugin.", proc do |json|
          json[:body_md] && json[:body_md].empty?
        end),
        Rule.new(:warning, 30, "Tags", "This plugin does not include `@tags tag1, tag2` and thus will be harder to find in search.", proc do |json|
          json[:tags] && json[:tags].empty?
        end),
        Rule.new(:warning, 29, "References", "Ideally, you have a reference implementation of your plugin that you can show to people, add `@see org/repo` to have the site auto link it.", proc do |json|
          json[:see] && json[:see].empty?
        end),
        Rule.new(:error, 8..27, "Examples", "You should include some examples of common use-cases for your plugin.", proc do |json|
          json[:example_code] && json[:example_code].empty?
        end)
      ]
    end

    def method_rules
      [
        Rule.new(:error, 40..41, "Description", "You should include a description for your method.", proc do |json|
          json[:body_md] && json[:body_md].empty?
        end),
        Rule.new(:warning, 43..45, "Params", "If the function has no useful return value, use ` @return  [void]`.", proc do |json|
          json[:param_couplets] && json[:param_couplets].flat_map(&:values).include?(nil)
        end),
        Rule.new(:warning, 46, "Return Type", "If the function has no useful return value, use ` @return  [void]` - this will be ignored by documentation generators.", proc do |json|
          json[:return] && json[:return].empty?
        end)
      ]
    end

    def link(ref)
      if ref.kind_of? Range
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{ref.min}#-L#{ref.max}"
      elsif ref.kind_of? Fixnum
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{ref}"
      else
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb"
      end
    end

    def apply_rules(json, rules)
      rules.each do |rule|
        next unless rule.function.call(json)
        rule.metadata = json

        case rule.modifier
        when :warning
          warnings << rule
        when :error
          errors << rule
        end
      end
    end

    def lint
      json.each do |plugin|
        apply_rules(plugin, class_rules)

        plugin[:methods].each do |method|
          apply_rules(method, method_rules)
        end
      end
    end

    def failed?
      errors.empty?
    end

    def print_summary(ui)
      if failed?
        ui.notice "Passed\n"
      else
        ui.puts "Failed linting\n".red
      end

      do_rules = proc do |name, rules|
        unless rules.empty?
          ui.section(name.bold) do
            rules.each do |rule|
              ui.labeled(rule.title + " - #{rule.object_applied_to}", [rule.description, link(rule.ref)])
              ui.puts ""
            end
          end
        end
      end

      do_rules.call("Errors", errors)
      do_rules.call("Warnings", warnings)
    end
  end
end
