# Handles printing all of the metadata currently residing in the plugins

module Danger
  class PluginPrinter
    def initialize(env, plugin_host, ui)
      @env = env
      @plugin_host = plugin_host
      @ui = ui
    end

    def core_dsl_attributes
      @plugin_host.core_plugins.map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
    end

    def external_dsl_attributes
      @plugin_host.plugins
                  .values
                  .reject { |plugin| @plugin_host.core_plugins.include? plugin }
                  .map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
    end

    def method_values_for_plugin_hashes(plugin_hashes)
      plugin_hashes.flat_map do |plugin_hash|
        plugin = plugin_hash[:plugin]
        methods = plugin_hash[:methods].select { |name| plugin.method(name).parameters.empty? }

        methods.map do |method|
          case method
          when :api
            value = "Octokit::Client"

          when :pr_json
            value = "[Skipped]"

          when :pr_body
            value = plugin.send(method)
            value = value.scan(/.{,80}/).to_a.each(&:strip!).join("\n")

          else
            value = plugin.send(method)
            # So that we either have one value per row
            # or we have [] for an empty array
            value = value.join("\n") if value.kind_of?(Array) && value.count > 0
          end

          [method.to_s, value]
        end
      end
    end

    # Iterates through the DSL's attributes, and table's the output
    def print_known_info
      rows = []
      rows += method_values_for_plugin_hashes(core_dsl_attributes)
      rows << ["---", "---"]
      rows += method_values_for_plugin_hashes(external_dsl_attributes)
      rows << ["---", "---"]
      rows << ["SCM", env.scm.class]
      rows << ["Source", env.ci_source.class]
      rows << ["Requests", env.request_source.class]
      rows << ["Base Commit", env.meta_info_for_base]
      rows << ["Head Commit", env.meta_info_for_head]

      params = {}
      params[:rows] = rows.each { |current| current[0] = current[0].yellow }
      params[:title] = "Danger v#{Danger::VERSION}\nDSL Attributes".green

      ui.section("Info:") do
        ui.puts
        ui.puts Terminal::Table.new(params)
        ui.puts
      end
    end
  end
end
