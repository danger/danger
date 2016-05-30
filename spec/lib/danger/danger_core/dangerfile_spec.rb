require 'pathname'
require 'tempfile'

require 'danger/danger_core/plugins/dangerfile_messaging_plugin'
require 'danger/danger_core/plugins/dangerfile_import_plugin'
require 'danger/danger_core/plugins/dangerfile_git_plugin'
require 'danger/danger_core/plugins/dangerfile_github_plugin'

describe Danger::Dangerfile do
  it 'keeps track of the original Dangerfile' do
    file = make_temp_file ""
    dm = testing_dangerfile
    dm.parse file.path
    expect(dm.defined_in_file).to eq file.path
  end

  it 'runs the ruby code inside the Dangerfile' do
    dangerfile_code = "message('hi')"
    expect_any_instance_of(Danger::DangerfileMessagingPlugin).to receive(:puts).and_return("")
    dm = testing_dangerfile
    dm.parse Pathname.new(""), dangerfile_code
  end

  it 'raises elegantly with bad ruby code inside the Dangerfile' do
    dangerfile_code = "asdas = asdasd + asdasddas"
    dm = testing_dangerfile

    expect do
      dm.parse Pathname.new(""), dangerfile_code
    end.to raise_error(Danger::DSLError)
  end

  it 'respects ignored violations' do
    allow(STDOUT).to receive(:puts) # this disables puts

    code = "message 'A message'\n" \
           "warn 'An ignored warning'\n" \
           "warn 'A warning'\n" \
           "fail 'An ignored error'\n" \
           "fail 'An error'\n"

    dm = testing_dangerfile
    dm.env.request_source.ignored_violations = ['A message', 'An ignored warning', 'An ignored error']

    dm.parse Pathname.new(""), code

    results = dm.status_report
    expect(results[:messages]).to eql(['A message'])
    expect(results[:errors]).to eql(['An error'])
    expect(results[:warnings]).to eql(['A warning'])
  end

  describe "#print_results" do
    it "Prints out 3 tables" do
      allow(STDOUT).to receive(:puts) # this disables puts

      code = "message 'A message'\n" \
             "warn 'Another warning'\n" \
             "warn 'A warning'\n" \
             "fail 'Another error'\n" \
             "fail 'An error'\n"
      dm = testing_dangerfile
      dm.env.request_source.ignored_violations = ['A message', 'An ignored warning', 'An ignored error']

      dm.parse Pathname.new(""), code

      expect(Terminal::Table).to receive(:new).with({
        rows: [["Another error"], ["An error"]],
        title: "Errors".red
      })
      expect(Terminal::Table).to receive(:new).with({
        rows: [["Another warning"], ["A warning"]],
        title: "Warnings".yellow
      })
      expect(Terminal::Table).to receive(:new).with({
        rows: [["A message"]],
        title: "Messages"
      })
      dm.print_results
    end
  end

  describe "verbose" do
    it 'outputs metadata when verbose' do
      file = make_temp_file ""
      dm = testing_dangerfile
      dm.verbose = true

      expect(dm).to receive(:print_known_info)
      dm.parse file.path
    end

    it 'does not print metadata by default' do
      file = make_temp_file ""
      dm = testing_dangerfile

      expect(dm).to_not receive(:print_known_info)
      dm.parse file.path
    end
  end

  describe 'initializing plugins' do
    it 'should add a plugin to the @plugins array' do
      class DangerTestPlugin < Danger::Plugin; end
      allow(ObjectSpace).to receive(:each_object).and_return([DangerTestPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect(dm.instance_variable_get('@plugins').length).to eq(1)
    end

    it 'should add an instance variable to the dangerfile' do
      class DangerTestPlugin < Danger::Plugin; end
      allow(ObjectSpace).to receive(:each_object).and_return([DangerTestPlugin])
      dm = testing_dangerfile
      allow(dm).to receive(:core_dsls).and_return([])
      dm.init_plugins

      expect { dm.test_plugin }.to_not raise_error
      expect(dm.test_plugin.class).to eq(DangerTestPlugin)
    end
  end
end
