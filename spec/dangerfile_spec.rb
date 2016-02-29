require 'pathname'
require 'tempfile'
require 'danger/dangerfile'
require 'danger/standard_error'

def make_temp_file(contents)
  file = Tempfile.new('dangefile_tests')
  file.write contents
  file
end

describe Danger::Dangerfile do
  it 'keeps track of the original Dangerfile' do
    file = make_temp_file ""
    dm = Danger::Dangerfile.new
    dm.parse file.path
    expect(dm.defined_in_file).to be file.path
  end

  it 'runs the ruby code inside the Dangerfile' do
    code = "message('hi')"
    expect_any_instance_of(Danger::Dangerfile).to receive(:puts).and_return("")
    dm = Danger::Dangerfile.new
    dm.parse Pathname.new(""), code
  end

  it 'raises elegantly with bad ruby code inside the Dangerfile' do
    code = "asdas = asdasd + asdasddas"
    dm = Danger::Dangerfile.new

    expect do
      dm.parse Pathname.new(""), code
    end.to raise_error(Danger::DSLError)
  end

  describe "verbose" do
    it 'outputs metadata when verbose' do
      file = make_temp_file ""
      dm = Danger::Dangerfile.new
      dm.verbose = true

      expect(dm).to receive(:print_known_info)
      dm.parse file.path
    end
    it 'does not print metadata by default' do
      file = make_temp_file ""
      dm = Danger::Dangerfile.new

      expect(dm).to_not receive(:print_known_info)
      dm.parse file.path
    end
  end
end
