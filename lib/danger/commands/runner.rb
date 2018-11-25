module Danger
  class Runner < CLAide::Command
    require "danger/commands/init"
    require "danger/commands/local"
    require "danger/commands/dry_run"
    require "danger/commands/systems"
    require "danger/commands/pr"

    # manually set claide plugins as a subcommand
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

    require "danger/commands/dangerfile/init"
    require "danger/commands/dangerfile/gem"

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
      if self.class == Runner && !@dangerfile_path
        help!("Could not find a Dangerfile.")
      end
    end

    def self.options
      [
        ["--base=[master|dev|stable]", "A branch/tag/commit to use as the base of the diff"],
        ["--head=[master|dev|stable]", "A branch/tag/commit to use as the head"],
        ["--fail-on-errors=<true|false>", "Should always fail the build process, defaults to false"],
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
