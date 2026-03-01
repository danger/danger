module Danger
  class PluginLinter
    # An internal class that is used to represent a rule for the linter.
    class Rule
      attr_accessor :modifier, :description, :title, :function, :ref, :metadata, :type

      def initialize(modifier, ref, title, description, function)
        @modifier = modifier
        @title = title
        @description = description
        @function = function
        @ref = ref
      end

      def object_applied_to
        metadata[:name].to_s.bold + " (" + type + ")"
      end
    end

    attr_accessor :json, :warnings, :errors

    def initialize(json)
      @json = json
      @warnings = []
      @errors = []
    end

    # Lints the current JSON, looking at:
    # * Class rules
    # * Method rules
    # * Attribute rules
    #
    def lint
      json.each do |plugin|
        apply_rules(plugin, "class", class_rules)

        plugin[:methods].each do |method|
          apply_rules(method, "method", method_rules)
        end

        plugin[:attributes].each do |method_hash|
          method_name = method_hash.keys.first
          method = method_hash[method_name]

          value = method[:write] || method[:read]
          apply_rules(value, "attribute", method_rules)
        end
      end
    end

    # Did the linter pass/fail?
    #
    def failed?
      errors.count > 0
    end

    # Prints a summary of the errors and warnings.
    #
    def print_summary(ui)
      # Print whether it passed/failed at the top
      if failed?
        ui.puts "\n[!] Failed\n".red
      else
        ui.notice "Passed"
      end

      # A generic proc to handle the similarities between
      # errors and warnings.
      do_rules = proc do |name, rules|
        unless rules.empty?
          ui.puts ""
          ui.section(name.bold) do
            rules.each do |rule|
              title = rule.title.bold + " - #{rule.object_applied_to}"
              subtitles = [rule.description, link(rule.ref)]
              subtitles += [rule.metadata[:files].join(":")] if rule.metadata[:files]
              ui.labeled(title, subtitles)
              ui.puts ""
            end
          end
        end
      end

      # Run the rules
      do_rules.call("Errors".red, errors)
      do_rules.call("Warnings".yellow, warnings)
    end

    private

    # Rules that apply to a class
    #
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

    # Rules that apply to individual methods, and attributes
    #
    def method_rules
      [
        Rule.new(:error, 40..41, "Description", "You should include a description for your method.", proc do |json|
          json[:body_md] && json[:body_md].empty?
        end),
        Rule.new(:warning, 43..45, "Params", "You should give a 'type' for the param, yes, ruby is duck-typey but it's useful for newbies to the language, use `@param [Type] name`.", proc do |json|
          json[:param_couplets] && json[:param_couplets].flat_map(&:values).include?(nil)
        end),
        Rule.new(:warning, 43..45, "Unknown Param", "You should give a 'type' for the param, yes, ruby is duck-typey but it's useful for newbies to the language, use `@param [Type] name`.", proc do |json|
          json[:param_couplets] && json[:param_couplets].flat_map(&:values).include?("Unknown")
        end),
        Rule.new(:warning, 46, "Return Type", "If the function has no useful return value, use ` @return  [void]` - this will be ignored by documentation generators.", proc do |json|
          return_hash = json[:tags].find { |tag| tag[:name] == "return" }
          !(return_hash && return_hash[:types] && !return_hash[:types].first.empty?)
        end)
      ]
    end

    # Generates a link to see an example of said rule
    #
    def link(ref)
      if ref.kind_of?(Range)
        "@see - " + "https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{ref.min}#-L#{ref.max}".blue
      elsif ref.kind_of?(Integer)
        "@see - " + "https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L#{ref}".blue
      else
        "@see - " + "https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb".blue
      end
    end

    # Runs the rule, if it fails then additional metadata
    # is added to the rule (for printing later) and it's
    # added to either `warnings` or `errors`.
    #
    def apply_rules(json, type, rules)
      rules.each do |rule|
        next unless rule.function.call(json)
        rule.metadata = json
        rule.type = type

        case rule.modifier
        when :warning
          warnings << rule
        when :error
          errors << rule
        end
      end
    end
  end
end
