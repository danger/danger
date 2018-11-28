require "pathname"
require "tempfile"

require "danger/danger_core/plugins/dangerfile_messaging_plugin"
require "danger/danger_core/plugins/dangerfile_danger_plugin"
require "danger/danger_core/plugins/dangerfile_git_plugin"
require "danger/danger_core/plugins/dangerfile_github_plugin"

RSpec.describe Danger::Dangerfile, host: :github do
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

    expect(results[:messages]).to eq(["A message"])
    expect(results[:errors]).to eq(["An error"])
    expect(results[:warnings]).to eq(["A warning"])
  end

  it "allows failure" do
    code = "fail 'fail1'\n" \
           "failure 'fail2'\n"
    dm = testing_dangerfile
    dm.parse Pathname.new(""), code
    results = dm.status_report

    expect(results[:errors]).to eq(["fail1", "fail2"])
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

      expect(dm).to receive(:print_list).with("Errors:".red, violations_factory(["Another error", "An error"], sticky: false))
      expect(dm).to receive(:print_list).with("Warnings:".yellow, violations_factory(["Another warning", "A warning"], sticky: false))
      expect(dm).to receive(:print_list).with("Messages:", violations_factory(["A message"], sticky: false))

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

  # Sidenote: If you're writing tests that touch the plugin infrastructure at runtime
  # you're going to have a bad time if they share the class name. Make them unique.

  describe "initializing plugins" do
    it "should add a plugin to the @plugins array" do
      class DangerTestAddingToArrayPlugin < Danger::Plugin; end
      allow(Danger::Plugin).to receive(:all_plugins).and_return([DangerTestAddingToArrayPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect(dm.instance_variable_get("@plugins").length).to eq(1)
    end

    it "should add an instance variable to the dangerfile" do
      class DangerTestAddingInstanceVarPlugin < Danger::Plugin; end
      allow(ObjectSpace).to receive(:each_object).and_return([DangerTestAddingInstanceVarPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect { dm.test_adding_instance_var_plugin }.to_not raise_error
      expect(dm.test_adding_instance_var_plugin.class).to eq(DangerTestAddingInstanceVarPlugin)
    end
  end

  describe "printing verbose metadata" do
    before do
      Danger::Plugin.clear_external_plugins
    end

    it "exposes core attributes" do
      dm = testing_dangerfile
      methods = dm.core_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort

      expect(methods).to eq %i(fail failure markdown message status_report violation_report warn)
    end

    # These are things that require scoped access
    it "exposes no external attributes by default" do
      dm = testing_dangerfile
      methods = dm.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
      expect(methods).to eq %i(
        added_files api base_commit branch_for_base branch_for_head commits
        deleted_files deletions diff diff_for_file dismiss_out_of_range_messages
        head_commit html_link import_dangerfile import_plugin info_for_file
        insertions lines_of_code modified_files mr_author mr_body mr_json
        mr_labels mr_title pr_author pr_body pr_diff pr_json pr_labels
        pr_title renamed_files review scm_provider tags
      )
    end

    it "exposes all external plugin attributes by default" do
      class DangerCustomAttributePlugin < Danger::Plugin
        attr_reader :my_thing
      end

      dm = testing_dangerfile
      methods = dm.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
      expect(methods).to include(:my_thing)
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

    describe "table metadata" do
      before do
        @dm = testing_dangerfile
        @dm.env.request_source.support_tokenless_auth = true

        # Stub out the GitHub stuff
        pr_reviews_response = JSON.parse(fixture("github_api/pr_reviews_response"))
        allow(@dm.env.request_source.client).to receive(:pull_request_reviews).with("artsy/eigen", "800").and_return(pr_reviews_response)
        pr_response = JSON.parse(fixture("github_api/pr_response"))
        allow(@dm.env.request_source.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)
        issue_response = JSON.parse(fixture("github_api/issue_response"))
        allow(@dm.env.request_source.client).to receive(:get).with("https://api.github.com/repos/artsy/eigen/issues/800").and_return(issue_response)
        diff_response = diff_fixture("pr_diff_response")
        allow(@dm.env.request_source.client).to receive(:pull_request).with("artsy/eigen", "800", accept: "application/vnd.github.v3.diff").and_return(diff_response)

        # Use a known diff from Danger's history:
        # https://github.com/danger/danger/compare/98c4f7760bb16300d1292bb791917d8e4990fd9a...9a424ecd5ad7404fa71cf2c99627d2882f0f02ce
        @dm.env.fill_environment_vars
        @dm.env.scm.diff_for_folder(".", from: "9a424ecd5ad7404fa71cf2c99627d2882f0f02ce", to: "98c4f7760bb16300d1292bb791917d8e4990fd9a")
      end

      it "creates a table from a selection of core DSL attributes info" do
        # Check out the method hashes of all plugin info
        data = @dm.method_values_for_plugin_hashes(@dm.core_dsl_attributes)

        # Ensure consistent ordering
        data = sort_data(data)

        expect(data).to eq [
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

        data = @dm.method_values_for_plugin_hashes(@dm.external_dsl_attributes)
        # Ensure consistent ordering, and only extract the keys
        data = sort_data(data).map { |d| d.first.to_sym }

        expect(data).to eq %i(
          added_files api base_commit branch_for_base branch_for_head commits
          deleted_files deletions diff head_commit insertions lines_of_code
          modified_files mr_author mr_body mr_json mr_labels mr_title
          pr_author pr_body pr_diff pr_json pr_labels pr_title
          renamed_files review scm_provider tags
        )
      end

      it "skips raw PR/MR JSON, and diffs" do
        data = @dm.method_values_for_plugin_hashes(@dm.external_dsl_attributes)

        data_hash = data
          .collect { |v| [v.first, v.last] }
          .flat_map
          .each_with_object({}) { |vals, accum| accum.store(vals[0], vals[1]) }

        expect(data_hash["pr_json"]).to eq("[Skipped JSON]")
        expect(data_hash["mr_json"]).to eq("[Skipped JSON]")
        expect(data_hash["pr_diff"]).to eq("[Skipped Diff]")
      end
    end
  end

  describe "#post_results" do
    it "delegates to corresponding request source" do
      env_manager = double("Danger::EnvironmentManager", pr?: true)
      request_source = double("Danger::RequestSources::GitHub")

      allow(env_manager).to receive_message_chain(:scm, :class) { Danger::GitRepo }
      allow(env_manager).to receive(:request_source) { request_source }

      dm = Danger::Dangerfile.new(env_manager, testing_ui)

      expect(request_source).to receive(:update_pull_request!)

      dm.post_results("danger-identifier", nil, nil)
    end

    it "delegates unique entries" do
      code = "message 'message one'\n" \
             "message 'message two'\n" \
             "message 'message one'\n" \
             "warn 'message one'\n" \
             "warn 'message two'\n" \
             "warn 'message two'\n"

      dm = testing_dangerfile
      dm.env.request_source.ignored_violations = []

      dm.parse Pathname.new(""), code

      results = dm.status_report

      expect(dm.env.request_source).to receive(:update_pull_request!).with(
        warnings: [anything, anything],
        errors: [],
        messages: [anything, anything],
        markdowns: [],
        danger_id: "danger-identifier",
        new_comment: nil,
        remove_previous_comments: nil
      )

      dm.post_results("danger-identifier", nil, nil)
    end
  end

  describe "#setup_for_running" do
    it "ensure branches setup and generate diff" do
      env_manager = double("Danger::EnvironmentManager", pr?: true)
      scm = double("Danger::GitRepo", class: Danger::GitRepo)
      request_source = double("Danger::RequestSources::GitHub")

      allow(env_manager).to receive(:scm) { scm }
      allow(env_manager).to receive(:request_source) { request_source }

      dm = Danger::Dangerfile.new(env_manager, testing_ui)

      expect(env_manager).to receive(:ensure_danger_branches_are_setup)
      expect(scm).to receive(:diff_for_folder)

      dm.setup_for_running("custom_danger_base", "custom_danger_head")
    end
  end

  describe "#run" do
    context "when exception occured" do
      before { allow(Danger).to receive(:danger_outdated?).and_return(false) }

      it "updates PR with an error" do
        path = Pathname.new(File.join("spec", "fixtures", "dangerfile_with_error"))
        env_manager = double("Danger::EnvironmentManager", {
          pr?: false,
          clean_up: true,
          fill_environment_vars: true,
          ensure_danger_branches_are_setup: false
        })
        scm = double("Danger::GitRepo", {
          class: Danger::GitRepo,
          diff_for_folder: true
        })
        request_source = double("Danger::RequestSources::GitHub")
        dm = Danger::Dangerfile.new(env_manager, testing_ui)

        allow(env_manager).to receive(:scm) { scm }
        allow(env_manager).to receive(:request_source) { request_source }

        expect(request_source).to receive(:update_pull_request!)

        expect do
          dm.run("custom_danger_base", "custom_danger_head", path, 1, false, false)
        end.to raise_error(Danger::DSLError)
      end

      it "doesn't crash if path is reassigned" do
        path = Pathname.new(File.join("spec", "fixtures", "dangerfile_with_error_and_path_reassignment"))
        env_manager = double("Danger::EnvironmentManager", {
          pr?: false,
          clean_up: true,
          fill_environment_vars: true,
          ensure_danger_branches_are_setup: false
        })
        scm = double("Danger::GitRepo", {
          class: Danger::GitRepo,
          diff_for_folder: true
        })
        request_source = double("Danger::RequestSources::GitHub")
        dm = Danger::Dangerfile.new(env_manager, testing_ui)

        allow(env_manager).to receive(:scm) { scm }
        allow(env_manager).to receive(:request_source) { request_source }

        expect(request_source).to receive(:update_pull_request!)

        expect do
          dm.run("custom_danger_base", "custom_danger_head", path, 1, false, false)
        end.to raise_error(Danger::DSLError)
      end

      after { allow(Danger).to receive(:danger_outdated?).and_call_original }
    end
  end
end
