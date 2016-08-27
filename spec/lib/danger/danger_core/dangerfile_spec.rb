require "pathname"
require "tempfile"

require "danger/danger_core/plugins/dangerfile_messaging_plugin"
require "danger/danger_core/plugins/dangerfile_danger_plugin"
require "danger/danger_core/plugins/dangerfile_git_plugin"
require "danger/danger_core/plugins/dangerfile_github_plugin"

describe Danger::Dangerfile, host: :github do
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
end
