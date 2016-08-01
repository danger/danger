module Danger
  class PluginPrinter
    def initialize(env, plugin_host, messaging, ui)
      @env = env
      @plugin_host = plugin_host
      @messaging = messaging
      @ui = ui
    end

    def print_results
      status = @messaging.status_report
      return if (status[:errors] + status[:warnings] + status[:messages] + status[:markdowns]).count.zero?

      ui.section("Results:") do
        [:errors, :warnings, :messages].each do |key|
          formatted = key.to_s.capitalize + ":"
          title = case key
                  when :errors
                    formatted.red
                  when :warnings
                    formatted.yellow
                  else
                    formatted
                  end
          rows = status[key]
          print_list(title, rows)
        end

        if status[:markdowns].count > 0
          @ui.section("Markdown:") do
            status[:markdowns].each do |current_markdown|
              @ui.puts current_markdown
            end
          end
        end
      end
    end

    def core_dsl_attributes
      @plugin_host.core_plugins.map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
    end

    def external_dsl_attributes
      @plugin_host.plugins.values.reject { |plugin| @core_plugins.include? plugin } .map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
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

    private

    def print_list(title, rows)
      ui.title(title) do
        rows.each do |row|
          ui.puts("- [ ] #{row}")
        end
      end unless rows.empty?
    end
  end
end
