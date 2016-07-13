require "pathname"
require "tempfile"

require "danger/danger_core/plugins/dangerfile_messaging_plugin"
require "danger/danger_core/plugins/dangerfile_import_plugin"
require "danger/danger_core/plugins/dangerfile_git_plugin"
require "danger/danger_core/plugins/dangerfile_github_plugin"

describe Danger::Dangerfile do
  it "keeps track of the original Dangerfile" do
    file = make_temp_file ""
    dm = testing_dangerfile
    dm.parse file.path
    expect(dm.defined_in_file).to eq file.path
  end

  it "runs the ruby code inside the Dangerfile" do
    dangerfile_code = "message('hi')"
    expect_any_instance_of(Danger::DangerfileMessagingPlugin).to receive(:message).and_return("")
    dm = testing_dangerfile
    dm.parse Pathname.new(""), dangerfile_code
  end

  it "raises elegantly with bad ruby code inside the Dangerfile" do
    dangerfile_code = "asdas = asdasd + asdasddas"
    dm = testing_dangerfile

    expect do
      dm.parse Pathname.new(""), dangerfile_code
    end.to raise_error(Danger::DSLError)
  end

  it "respects ignored violations" do
    code = "message 'A message'\n" \
           "warn 'An ignored warning'\n" \
           "warn 'A warning'\n" \
           "fail 'An ignored error'\n" \
           "fail 'An error'\n"

    dm = testing_dangerfile
    dm.env.request_source.ignored_violations = ["A message", "An ignored warning", "An ignored error"]

    dm.parse Pathname.new(""), code

    results = dm.status_report
    expect(results[:messages]).to eql(["A message"])
    expect(results[:errors]).to eql(["An error"])
    expect(results[:warnings]).to eql(["A warning"])
  end

  describe "#print_results" do
    it "Prints out 3 lists" do
      code = "message 'A message'\n" \
             "warn 'Another warning'\n" \
             "warn 'A warning'\n" \
             "fail 'Another error'\n" \
             "fail 'An error'\n"
      dm = testing_dangerfile
      dm.env.request_source.ignored_violations = ["A message", "An ignored warning", "An ignored error"]

      dm.parse Pathname.new(""), code

      expect(dm).to receive(:print_list).with("Errors:".red, ["Another error", "An error"])
      expect(dm).to receive(:print_list).with("Warnings:".yellow, ["Another warning", "A warning"])
      expect(dm).to receive(:print_list).with("Messages:", ["A message"])

      dm.print_results
    end
  end

  describe "verbose" do
    it "outputs metadata when verbose" do
      file = make_temp_file ""
      dm = testing_dangerfile
      dm.verbose = true

      expect(dm).to receive(:print_known_info)
      dm.parse file.path
    end

    it "does not print metadata by default" do
      file = make_temp_file ""
      dm = testing_dangerfile

      expect(dm).to_not receive(:print_known_info)
      dm.parse file.path
    end
  end

  describe "initializing plugins" do
    it "should add a plugin to the @plugins array" do
      class DangerTestPlugin < Danger::Plugin; end
      allow(Danger::Plugin).to receive(:all_plugins).and_return([DangerTestPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect(dm.instance_variable_get("@plugins").length).to eq(1)
    end

    it "should add an instance variable to the dangerfile" do
      class DangerTestPlugin < Danger::Plugin; end
      allow(ObjectSpace).to receive(:each_object).and_return([DangerTestPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect { dm.test_plugin }.to_not raise_error
      expect(dm.test_plugin.class).to eq(DangerTestPlugin)
    end
  end

  describe "printing verbose metadata" do
    it "exposes core attributes" do
      dm = testing_dangerfile
      methods = dm.core_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort

      expect(methods).to eq [
        :added_files,
        :api,
        :base_commit,
        :branch_for_base,
        :branch_for_head,
        :commits,
        :deleted_files,
        :deletions,
        :download,
        :fail,
        :head_commit,
        :import,
        :insertions,
        :lines_of_code,
        :markdown,
        :message,
        :modified_files,
        :pr_author,
        :pr_body,
        :pr_json,
        :pr_labels,
        :pr_title,
        :status_report,
        :violation_report,
        :warn
      ]
    end

    # NOTE: :protect_files comes from this repo, it is considered a "Danger" plugin, for
    # danger, not one that is shipped _with danger_. It is included here, because it

    it "exposes no external attributes by default" do
      dm = testing_dangerfile
      methods = dm.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
      expect(methods).to eq []
    end

    it "exposes plugin external attributes by default" do
      class DangerCustomAttributePlugin < Danger::Plugin
        attr_reader :my_thing
      end

      dm = testing_dangerfile
      methods = dm.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
      expect(methods).to eq [:my_thing]
    end

    def sort_data(data)
      data.sort do |a, b|
        if a.first < b.first
          -1
        else
          (a.first > b.first ? 1 : (a.first <=> b.first))
        end
      end
    end

    it "creates a table from a selection of core DSL attributes info" do
      dm = testing_dangerfile
      dm.env.request_source.support_tokenless_auth = true

      # Stub out the GitHub stuff
      pr_response = JSON.parse(fixture("pr_response"), symbolize_names: true)
      allow(dm.env.request_source.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)
      issue_response = JSON.parse(fixture("issue_response"), symbolize_names: true)
      allow(dm.env.request_source.client).to receive(:get).with("https://api.github.com/repos/artsy/eigen/issues/800").and_return(issue_response)

      # Use a diff from Danger's history:
      # https://github.com/danger/danger/compare/98c4f7760bb16300d1292bb791917d8e4990fd9a...9a424ecd5ad7404fa71cf2c99627d2882f0f02ce
      dm.env.fill_environment_vars
      dm.env.scm.diff_for_folder(".", from: "9a424ecd5ad7404fa71cf2c99627d2882f0f02ce", to: "98c4f7760bb16300d1292bb791917d8e4990fd9a")

      # Check out the method hashes of all plugin info
      data = dm.method_values_for_plugin_hashes(dm.core_dsl_attributes)

      # Ensure consistent ordering
      data = sort_data(data)

      expect(data).to eq [
        ["added_files", []],
        ["api", "Octokit::Client"],
        ["base_commit", "704dc55988c6996f69b6873c2424be7d1de67bbe"],
        ["branch_for_base", "master"],
        ["branch_for_head", "orta-circle_ci2"],
        ["commits", []],
        ["deleted_files", []],
        ["deletions", 60],
        ["head_commit", "561827e46167077b5e53515b4b7349b8ae04610b"],
        ["insertions", 15],
        ["lines_of_code", 75],
        ["modified_files", "CHANGELOG.md\nlib/danger/ci_source/local_git_repo.rb\nlib/danger/commands/local.rb\nlib/danger/commands/new_plugin.rb\nlib/danger/commands/runner.rb\nlib/danger/environment_manager.rb\nspec/sources/local_git_repo_spec.rb"],
        ["pr_author", "orta"],
        ["pr_body", "![](http://media4.giphy.com/media/Ksn86eRmE2taM/giphy.gif)\n\n> Danger: Ignore \"Developer Specific file shouldn't be changed\"\n\n> Danger: Ignore \"Some warning\"\n"],
        ["pr_json", "[Skipped]"],
        ["pr_labels", "D:2\nMaintenance Work"],
        ["pr_title", "[CI] Use Xcode 7 for Circle CI"],
        ["status_report", { errors: [], warnings: [], messages: [], markdowns: [] }],
        ["violation_report", { errors: [], warnings: [], messages: [] }]
      ]
    end

    it "creates a table from a selection of external plugins DSL attributes info" do
      class DangerCustomAttributeTwoPlugin < Danger::Plugin
        def something
          "value_for_something"
        end
      end

      dm = testing_dangerfile

      data = dm.method_values_for_plugin_hashes(dm.external_dsl_attributes)
      # Ensure consistent ordering
      data = sort_data(data)

      expect(data).to eq [
        ["my_thing", nil],
        ["something", "value_for_something"]
      ]
    end
  end
end
