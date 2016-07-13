module Danger
  class PluginLinter
    class Rule
      attr_accessor :modifier, :description, :title, :function

      def initialize(modifier, title, description, function)
        @modifier = modifier
        @title = title
        @description = description
        @function = function
      end

      def reference
        ""
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
        Rule.new(:warning, "Tags", "This plugin does not include `@tags tag1, tag2` and thus will be harder to find in search.", proc do |json|
          json[:tags] && json[:tags].empty?
        end),
        Rule.new(:warning, "References", "Ideally you have a reference implementation of your plugin that you can show to people, add `@see org/repo` to have the site auto link it.", proc do |json|
          json[:see] && json[:see].empty?
        end),
        Rule.new(:error, "Description Markdown", "Above your class you need documentation that covers the scope, and the usage of your plugin", proc do |json|
          json[:body_md] && json[:body_md].empty?
        end),
        Rule.new(:error, "Examples", "Above your class you need documentation that covers the scope, and the usage of your plugin", proc do |json|
          json[:example_code] && json[:example_code].empty?
        end)
      ]
    end

    def method_rules
      [
        Rule.new(:error, "Description", "This plugin does not include `@tags tag1, tag2` and thus will be harder to find in search.", proc do |json|
          json[:body_md] && json[:body_md].empty?
        end),
        Rule.new(:warning, "Params", "If the function has no useful return value, use ` @return  [void]`.", proc do |json|
          json[:param_couplets] && json[:param_couplets].flat_map(&:values).include?(nil)
        end),
        Rule.new(:warning, "Return Type", "If the function has no useful return value, use ` @return  [void]` - this will be ignored by documentation generators.", proc do |json|
          json[:return] && json[:return].empty?
        end)
      ]
    end

    def link(first = nil, last = nil)
      if first && last
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{first}#-L#{last}"
      elsif first
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{first}"
      else
        "@see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb"
      end
    end

    def apply_rules(json, rules)
      rules.each do |rule|
        next unless rule.function.call(json)

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

    def print_summary(ui)
      if errors.empty?
        ui.notice "Passed linting"
      end

      unless errors.empty?
        ui.section("Errors") do
          errors.each do |error|
            ui.labeled(error.title, [error.description, error.reference])
          end
        end
      end

      unless warnings.empty?
        ui.section("Warnings") do
          warnings.each do |error|
            ui.labeled(error.title, [error.description, error.reference])
          end
        end
      end

    end
  end
end
