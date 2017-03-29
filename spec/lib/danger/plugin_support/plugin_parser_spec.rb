require "danger/plugin_support/plugin_parser"

RSpec.describe Danger::PluginParser do
  it "includes an example plugin" do
    parser = described_class.new "spec/fixtures/plugins/example_broken.rb"
    parser.parse

    plugin_docs = parser.registry.at("Danger::Dangerfile::ExampleBroken")
    expect(plugin_docs).to be_truthy
  end

  it "finds classes from inside the file" do
    parser = described_class.new "spec/fixtures/plugins/example_broken.rb"
    parser.parse

    classes = parser.classes_in_file

    class_syms = classes.map(&:name)
    expect(class_syms).to eq %i(Dangerfile ExampleBroken)
  end

  it "skips non-subclasses of Danger::Plugin" do
    parser = described_class.new "spec/fixtures/plugins/example_broken.rb"
    parser.parse

    plugins = parser.plugins_from_classes(parser.classes_in_file)

    class_syms = plugins.map(&:name)
    expect(class_syms).to eq []
  end

  it "find subclasses of Danger::Plugin" do
    parser = described_class.new "spec/fixtures/plugins/example_remote.rb"
    parser.parse

    plugins = parser.plugins_from_classes(parser.classes_in_file)

    class_syms = plugins.map(&:name)
    expect(class_syms).to eq [:ExampleRemote]
  end

  it "outputs JSON for badly documented subclasses of Danger::Plugin" do
    parser = described_class.new "spec/fixtures/plugins/example_remote.rb"
    parser.parse

    plugins = parser.plugins_from_classes(parser.classes_in_file)
    json = parser.to_h(plugins)
    sanitized_json = JSON.pretty_generate(json).gsub(Dir.pwd, "")

    fixture = "spec/fixtures/plugin_json/example_remote.json"
    # File.write(fixture, sanitized_json)

    # Skipping this test for windows, pathing gets complex, and no-one
    # is generating gem docs on windows.
    if Gem.win_platform?
      expect(1).to eq(1)
    else
      expect(sanitized_json).to eq File.read(fixture)
    end
  end

  it "outputs JSON for well documented subclasses of Danger::Plugin" do
    parser = described_class.new "spec/fixtures/plugins/example_fully_documented.rb"
    parser.parse

    plugins = parser.plugins_from_classes(parser.classes_in_file)
    json = parser.to_h(plugins)
    sanitized_json = JSON.pretty_generate(json).gsub(Dir.pwd, "")

    fixture = "spec/fixtures/plugin_json/example_fully_doc.json"
    # File.write(fixture, sanitized_json)

    # Skipping this test for windows, pathing gets complex, and no-one
    # is generating gem docs on windows.
    if Gem.win_platform?
      expect(1).to eq(1)
    else
      expect(sanitized_json).to eq File.read(fixture)
    end
  end

  it "creates method descriptions that make sense" do
    parser = described_class.new "spec/fixtures/plugins/plugin_many_methods.rb"
    parser.parse

    plugins = parser.plugins_from_classes(parser.classes_in_file)
    json = parser.to_h(plugins)
    method_one_liners = json.first[:methods].map { |m| m[:one_liner] }

    expect(method_one_liners).to eq([
                                      "one",
                                      "two",
                                      "two_point_five",
                                      "three(param1=nil: String)",
                                      "four(param1=nil: Number, param2: String) -> String",
                                      "five(param1=[]: Array<String>, param2: Filepath, param3: Unknown) -> String",
                                      "six? -> Bool"
                                    ])
  end
end
