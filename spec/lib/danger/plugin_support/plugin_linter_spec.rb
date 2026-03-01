require "danger/plugin_support/plugin_parser"
require "danger/plugin_support/plugin_linter"

def json_doc_for_path(path)
  parser = Danger::PluginParser.new path
  parser.parse
  parser.to_json
end

RSpec.describe Danger::PluginParser do
  it "creates a set of errors for fixtured plugins" do
    json = json_doc_for_path("spec/fixtures/plugins/plugin_many_methods.rb")
    linter = Danger::PluginLinter.new(json)
    linter.lint
    titles = ["Description Markdown", "Examples", "Description", "Description"]
    expect(linter.errors.map(&:title)).to eq(titles)
  end

  it "creates a set of warnings for fixtured plugins" do
    json = json_doc_for_path("spec/fixtures/plugins/plugin_many_methods.rb")
    linter = Danger::PluginLinter.new(json)
    linter.lint

    titles = ["Tags", "References", "Return Type", "Return Type", "Return Type", "Unknown Param", "Return Type"]
    expect(linter.warnings.map(&:title)).to eq(titles)
  end

  it "fails when there are errors" do
    linter = Danger::PluginLinter.new({})
    expect(linter.failed?).to eq(false)

    linter.warnings = [1, 2, 3]
    expect(linter.failed?).to eq(false)

    linter.errors = [1, 2, 3]
    expect(linter.failed?).to eq(true)
  end

  it "handles outputting a warning" do
    ui = testing_ui
    linter = Danger::PluginLinter.new({})
    warning = Danger::PluginLinter::Rule.new(:warning, 30, "Example Title", "Example Description", nil)
    warning.metadata = { name: "NameOfExample" }
    warning.type = "TypeOfThing"

    linter.warnings << warning

    linter.print_summary(ui)

    expect(ui.string).to eq("\n[!] Passed\n\nWarnings\n  - Example Title - NameOfExample (TypeOfThing):\n    - Example Description\n    - @see - https://github.com/dbgrandi/danger-prose/blob/v2.0.0/lib/danger_plugin.rb#L30\n\n")
  end
end
