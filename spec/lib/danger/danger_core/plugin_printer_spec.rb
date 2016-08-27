# it "can handle printing its plugins" do
#   subject = Danger::PluginHost.new

#   dm = testing_dangerfile
#   subject.refresh_plugins(dm)
#   subject.print_results(dm)

#   expect(dm.ui.string).to eq("s")
# end

require "danger/danger_core/plugin_host"
require "danger/danger_core/plugin_printer"

describe Danger::PluginPrinter, host: :github do
  before do
    Danger::Plugin.clear_external_plugins

    @host = Danger::PluginHost.new
    @dm = testing_dangerfile
    @host.refresh_plugins(@dm)

    @subject = @host.printer
  end

  it "exposes core attributes" do
    methods = @subject.core_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
    expect(methods).to eq [:fail, :markdown, :message, :status_report, :violation_report, :warn]
  end

  # These are things that require scoped access
  it "exposes no external attributes by default" do
    methods = @subject.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
    expect(methods).to eq [:added_files, :api, :base_commit, :branch_for_base, :branch_for_head, :commits, :deleted_files, :deletions, :diff_for_file, :head_commit, :html_link, :import_dangerfile, :import_plugin, :insertions, :lines_of_code, :modified_files, :mr_author, :mr_body, :mr_json, :mr_labels, :mr_title, :pr_author, :pr_body, :pr_diff, :pr_json, :pr_labels, :pr_title]
  end

  it "exposes all external plugin attributes by default" do
    class DangerCustomAttributePlugin < Danger::Plugin
      attr_reader :my_thing
    end

    # refresh all the plugins
    @host.refresh_plugins(@dm)
    @subject = @host.printer

    methods = @subject.external_dsl_attributes.map { |hash| hash[:methods] }.flatten.sort
    expect(methods).to eq [:added_files, :api, :base_commit, :branch_for_base, :branch_for_head, :commits, :deleted_files, :deletions, :diff_for_file, :head_commit, :html_link, :import_dangerfile, :import_plugin, :insertions, :lines_of_code, :modified_files, :mr_author, :mr_body, :mr_json, :mr_labels, :mr_title, :my_thing,

                           :pr_author, :pr_body, :pr_diff, :pr_json, :pr_labels, :pr_title]
  end

  describe "table metadata" do
    before do
      @dm.env.request_source.support_tokenless_auth = true

      # Stub out the GitHub stuff
      pr_response = JSON.parse(fixture("github_api/pr_response"), symbolize_names: true)
      allow(@dm.env.request_source.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)
      issue_response = JSON.parse(fixture("github_api/issue_response"), symbolize_names: true)
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
      data = @subject.method_values_for_plugin_hashes(@subject.core_dsl_attributes)

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

      # refresh all the plugins
      @host.refresh_plugins(@dm)
      @subject = @host.printer

      data = @subject.method_values_for_plugin_hashes(@subject.external_dsl_attributes)
      # Ensure consistent ordering, and only extract the keys
      data = sort_data(data).map { |d| d.first.to_sym }

      expect(data).to eq [:added_files, :api, :base_commit, :branch_for_base, :branch_for_head, :commits, :deleted_files, :deletions, :head_commit, :insertions, :lines_of_code, :modified_files, :mr_author, :mr_body, :mr_json, :mr_labels, :mr_title, :pr_author, :pr_body, :pr_diff, :pr_json, :pr_labels, :pr_title, :something]
    end
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
end
