# frozen_string_literal: true

module Danger
  class Runner < CLAide::Command
    require "danger/commands/init"
    require "danger/commands/local"
    require "danger/commands/dry_run"
    require "danger/commands/staging"
    require "danger/commands/systems"
    require "danger/commands/pr"
    require "danger/commands/mr"

    require "danger/commands/dangerfile/init"

    attr_accessor :cork

    self.summary = "Run the Dangerfile."
    self.command = "danger"
    self.version = Danger::VERSION

    self.plugin_prefixes = %w(claide danger)

    def initialize(argv)
      dangerfile = argv.option("dangerfile", "Dangerfile")
      @dangerfile_path = dangerfile if File.exist?(dangerfile)
      @base = argv.option("base")
      @head = argv.option("head")
      @fail_on_errors = argv.option("fail-on-errors", false)
      @fail_if_no_pr = argv.option("fail-if-no-pr", false)
      @new_comment = argv.flag?("new-comment")
      @remove_previous_comments = argv.flag?("remove-previous-comments")
      @danger_id = argv.option("danger_id", "danger")
      @cork = Cork::Board.new(silent: argv.option("silent", false),
                              verbose: argv.option("verbose", false))
      adjust_colored2_output(argv)
      super
    end

    def validate!
      super
      if self.instance_of?(Runner) && !@dangerfile_path
        help!("Could not find a Dangerfile.")
      end
    end

    # Loads the subcommands that are backed by claide-plugins. Deferred out of the class
    # body so that
    # `require "danger"` does not pull in claide-plugins: it is only needed to run the
    # CLI, and loading it emits a "circular require considered harmful" warning from
    # inside the gem (claide/command/gem_helper.rb and gem_index_cache.rb require each
    # other), which every library consumer would otherwise print. Idempotent, so
    # repeated CLI entry is safe.
    def self.load_plugin_commands!
      return if @plugin_commands_loaded

      @plugin_commands_loaded = true

      require "claide_plugin"
      @subcommands << CLAide::Command::Plugins
      CLAide::Plugins.config =
        CLAide::Plugins::Configuration.new(
          "Danger",
          "danger",
          "https://gitlab.com/danger-systems/danger.systems/raw/master/plugins-search-generated.json",
          "https://github.com/danger/danger-plugin-template"
        )

      require "danger/commands/plugins/plugin_lint"
      require "danger/commands/plugins/plugin_json"
      require "danger/commands/plugins/plugin_readme"

      # `danger dangerfile gem` uses CLAide::TemplateRunner, which claide-plugins
      # provides, so it belongs on this side of the split too.
      require "danger/commands/dangerfile/gem"
    end

    # Every CLI entry point goes through here, so the plugins subcommand is registered
    # before CLAide dispatches regardless of how danger was invoked.
    def self.run(argv)
      load_plugin_commands!
      super
    end

    def self.options
      [
        ["--base=[master|dev|stable]", "A branch/tag/commit to use as the base of the diff"],
        ["--head=[master|dev|stable]", "A branch/tag/commit to use as the head"],
        ["--fail-on-errors=<true|false>", "Should always fail the build process, defaults to false"],
        ["--fail-if-no-pr=<true|false>", "Should fail the build process if no PR is found (useful for CircleCI), defaults to false"],
        ["--dangerfile=<path/to/dangerfile>", "The location of your Dangerfile"],
        ["--danger_id=<id>", "The identifier of this Danger instance"],
        ["--new-comment", "Makes Danger post a new comment instead of editing its previous one"],
        ["--remove-previous-comments", "Removes all previous comment and create a new one in the end of the list"]
      ].concat(super)
    end

    def run
      Executor.new(ENV).run(
        base: @base,
        head: @head,
        dangerfile_path: @dangerfile_path,
        danger_id: @danger_id,
        new_comment: @new_comment,
        fail_on_errors: @fail_on_errors,
        fail_if_no_pr: @fail_if_no_pr,
        remove_previous_comments: @remove_previous_comments
      )
    end

    private

    def adjust_colored2_output(argv)
      # disable/enable colored2 output
      # consider it execution wide to avoid need to wrap #run and maintain state
      # ARGV#options is non-destructive way to check flags
      Colored2.public_send(argv.options.fetch("ansi", true) ? "enable!" : "disable!")
    end
  end
end
