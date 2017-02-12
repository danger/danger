require "danger/commands/local_helpers/pry_setup"

RSpec.describe Danger::PrySetup do
  before { cleanup }
  after { cleanup }

  describe "#setup_pry" do
    it "copies the Dangerfile and appends bindings.pry" do
      Dir.mktmpdir do |dir|
        dangerfile_path = "#{dir}/Dangerfile"
        File.write(dangerfile_path, "")

        dangerfile_copy = described_class
          .new(testing_ui)
          .setup_pry(dangerfile_path)

        expect(File).to exist(dangerfile_copy)
        expect(File.read(dangerfile_copy)).to include("binding.pry; File.delete(\"_Dangerfile.tmp\")")
      end
    end

    it "doesn't copy a nonexistant Dangerfile" do
      described_class.new(testing_ui).setup_pry("")

      expect(File).not_to exist("_Dangerfile.tmp")
    end

    it "warns when the pry gem is not installed" do
      ui = testing_ui
      expect(Kernel).to receive(:require).with("pry").and_raise(LoadError)

      expect do
        described_class.new(ui).setup_pry("Dangerfile")
      end.to raise_error(SystemExit)
      expect(ui.err_string).to include("Pry was not found")
    end

    def cleanup
      File.delete "_Dangerfile.tmp" if File.exist? "_Dangerfile.tmp"
    end
  end
end
