# So much was ripped direct from CocoaPods-Core - thanks!

require "danger/danger_core/dangerfile_dsl"
require "danger/danger_core/standard_error"
require "danger/danger_core/message_aggregator"

require "danger/danger_core/plugins/dangerfile_messaging_plugin"
require "danger/danger_core/plugins/dangerfile_danger_plugin"
require "danger/danger_core/plugins/dangerfile_git_plugin"
require "danger/danger_core/plugins/dangerfile_github_plugin"
require "danger/danger_core/plugins/dangerfile_gitlab_plugin"
require "danger/danger_core/plugins/dangerfile_bitbucket_server_plugin"
require "danger/danger_core/plugins/dangerfile_bitbucket_cloud_plugin"
require "danger/danger_core/plugins/dangerfile_vsts_plugin"
require "danger/danger_core/plugins/dangerfile_local_only_plugin"

module Danger
  class Dangerfile
    include Danger::Dangerfile::DSL

    attr_accessor :env, :verbose, :plugins, :ui

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the Dangerfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      "Dangerfile"
    end

    # These are the classes that are allowed to also use method_missing
    # in order to provide broader plugin support
    def self.core_plugin_classes
      [DangerfileMessagingPlugin]
    end

    # The ones that everything would break without
    def self.essential_plugin_classes
      [DangerfileMessagingPlugin, DangerfileGitPlugin, DangerfileDangerPlugin, DangerfileGitHubPlugin, DangerfileGitLabPlugin, DangerfileBitbucketServerPlugin, DangerfileBitbucketCloudPlugin, DangerfileVSTSPlugin, DangerfileLocalOnlyPlugin]
    end

    # Both of these methods exist on all objects
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-warn
    # http://ruby-doc.org/core-2.2.3/Kernel.html#method-i-fail
    # However, as we're using using them in the DSL, they won't
    # get method_missing called correctly without overriding them.

    def warn(*args, &blk)
      method_missing(:warn, *args, &blk)
    end

    def fail(*args, &blk)
      method_missing(:fail, *args, &blk)
    end

    # When an undefined method is called, we check to see if it's something
    # that the core DSLs have, then starts looking at plugins support.

    # rubocop:disable Style/MethodMissing
    def method_missing(method_sym, *arguments, &_block)
      @core_plugins.each do |plugin|
        if plugin.public_methods(false).include?(method_sym)
          return plugin.send(method_sym, *arguments)
        end
      end
      super
    end

    # cork_board not being set comes from plugins #585
    def initialize(env_manager, cork_board = nil)
      @plugins = {}
      @core_plugins = []
      @ui = cork_board || Cork::Board.new(silent: false, verbose: false)

      # Triggers the core plugins
      @env = env_manager

      # Triggers local plugins from the root of a project
      Dir["./danger_plugins/*.rb"].each do |file|
        require File.expand_path(file)
      end

      refresh_plugins if env_manager.pr?
    end

    # Iterate through available plugin classes and initialize them with
    # a reference to this Dangerfile
    def refresh_plugins
      plugins = Plugin.all_plugins
      plugins.each do |klass|
        next if klass.respond_to?(:singleton_class?) && klass.singleton_class?
        plugin = klass.new(self)
        next if plugin.nil? || @plugins[klass]

        name = plugin.class.instance_name
        self.class.send(:attr_reader, name)
        instance_variable_set("@#{name}", plugin)

        @plugins[klass] = plugin
        @core_plugins << plugin if self.class.core_plugin_classes.include? klass
      end
    end
    alias init_plugins refresh_plugins

    def core_dsl_attributes
      @core_plugins.map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
    end

    def external_dsl_attributes
      plugins.values.reject { |plugin| @core_plugins.include? plugin } .map { |plugin| { plugin: plugin, methods: plugin.public_methods(false) } }
    end

    def method_values_for_plugin_hashes(plugin_hashes)
      plugin_hashes.flat_map do |plugin_hash|
        plugin = plugin_hash[:plugin]
        methods = plugin_hash[:methods].select { |name| plugin.method(name).parameters.empty? }

        methods.map do |method|
          case method
          when :api
            value = "Octokit::Client"

          when :pr_json, :mr_json
            value = "[Skipped JSON]"

          when :pr_diff, :mr_diff
            value = "[Skipped Diff]"

          else
            value = plugin.send(method)
            value = wrap_text(value.encode("utf-8")) if value.kind_of?(String)
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
        table = Terminal::Table.new(params)
        table.align_column(0, :right)
        ui.puts table
        ui.puts
      end
    end

    # Parses the file at a path, optionally takes the content of the file for DI
    #
    def parse(path, contents = nil)
      print_known_info if verbose

      contents ||= File.open(path, "r:utf-8", &:read)

      # Work around for Rubinius incomplete encoding in 1.9 mode
      if contents.respond_to?(:encoding) && contents.encoding.name != "UTF-8"
        contents.encode!("UTF-8")
      end

      if contents.tr!("“”‘’‛", %(""'''))
        # Changes have been made
        ui.puts "Your #{path.basename} has had smart quotes sanitised. " \
          "To avoid issues in the future, you should not use " \
          "TextEdit for editing it. If you are not using TextEdit, " \
          "you should turn off smart quotes in your editor of choice.".red
      end

      if contents.include?("puts")
        ui.puts "You used `puts` in your Dangerfile. To print out text to GitHub use `message` instead"
      end

      self.defined_in_file = path
      instance_eval do
        # rubocop:disable Lint/RescueException
        begin
          eval_file(contents, path)
        rescue Exception => e
          message = "Invalid `#{path.basename}` file: #{e.message}"
          raise DSLError.new(message, path, e.backtrace, contents)
        end
        # rubocop:enable Lint/RescueException
      end
    end

    def print_results
      status = status_report
      violations = violation_report
      return if (violations[:errors] + violations[:warnings] + violations[:messages] + status[:markdowns]).count.zero?

      ui.section("Results:") do
        %i(errors warnings messages).each do |key|
          formatted = key.to_s.capitalize + ":"
          title = case key
                  when :errors
                    formatted.red
                  when :warnings
                    formatted.yellow
                  else
                    formatted
                  end
          rows = violations[key].uniq
          print_list(title, rows)
        end

        if status[:markdowns].count > 0
          ui.title("Markdown:") do
            status[:markdowns].each do |current_markdown|
              ui.puts "#{current_markdown.file}\#L#{current_markdown.line}" if current_markdown.file && current_markdown.line
              ui.puts current_markdown.message
            end
          end
        end
      end
    end

    def failed?
      violation_report[:errors].count > 0
    end

    def post_results(danger_id, new_comment, remove_previous_comments)
      violations = violation_report
      report = {
          warnings: violations[:warnings].uniq,
          errors: violations[:errors].uniq,
          messages: violations[:messages].uniq,
          markdowns: status_report[:markdowns].uniq,
          danger_id: danger_id
      }

      if env.request_source.respond_to?(:update_pr_by_line!) && ENV["DANGER_MESSAGE_AGGREGATION"]
        env.request_source.update_pr_by_line!(message_groups: MessageAggregator.aggregate(**report),
                                             new_comment: new_comment,
                                             remove_previous_comments: remove_previous_comments,
                                             danger_id: report[:danger_id])
      else
        env.request_source.update_pull_request!(
          **report,
          new_comment: new_comment,
          remove_previous_comments: remove_previous_comments
        )
      end
    end

    def setup_for_running(base_branch, head_branch)
      env.ensure_danger_branches_are_setup
      env.scm.diff_for_folder(".".freeze, from: base_branch, to: head_branch, lookup_top_level: true)
    end

    def run(base_branch, head_branch, dangerfile_path, danger_id, new_comment, remove_previous_comments)
      # Setup internal state
      init_plugins
      env.fill_environment_vars

      begin
        # Sets up the git environment
        setup_for_running(base_branch, head_branch)

        # Parse the local Dangerfile
        parse(Pathname.new(dangerfile_path))

        # Push results to the API
        # Pass along the details of the run to the request source
        # to send back to the code review site.
        post_results(danger_id, new_comment, remove_previous_comments) unless danger_id.nil?

        # Print results in the terminal
        print_results
      rescue DSLError => ex
        # Push exception to the API and re-raise
        post_exception(ex, danger_id, new_comment) unless danger_id.nil?
        raise
      ensure
        # Makes sure that Danger specific git branches are cleaned
        env.clean_up
      end

      failed?
    end

    private

    def eval_file(contents, path)
      eval(contents, nil, path.to_s) # rubocop:disable Eval
    end

    def print_list(title, rows)
      unless rows.empty?
        ui.title(title) do
          rows.each do |row|
            if row.file && row.line
              path = "#{row.file}\#L#{row.line}: "
            else
              path = ""
            end

            ui.puts("- [ ] #{path}#{row.message}")
          end
        end
      end
    end

    def wrap_text(text, width = 80)
      text.gsub(/.{,#{width}}/) do |line|
        line.strip!
        "#{line}\n"
      end
    end

    def post_exception(ex, danger_id, new_comment)
      env.request_source.update_pull_request!(
        danger_id: danger_id,
        new_comment: new_comment,
        markdowns: [ex.to_markdown]
      )
    end
  end
end
