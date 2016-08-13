require "danger/danger_core/executor"

describe Danger::Executor do
  describe "finding a Dangerfile" do

    it "should add a plugin to the dangerfile plugins array" do
      subject = Danger::Executor.new
      allow(File).to receive(:exist?).with("Dangerfile").and_return(true)

      expect(subject.path_for_implicit_dangerfile).to eq("Dangerfile")
    end

    it "should add a plugin to the dangerfile plugins array" do
      subject = Danger::Executor.new
      allow(File).to receive(:exist?).with("Dangerfile").and_return(false)
      allow(File).to receive(:exist?).with("Dangerfile.rb").and_return(false)
      allow(File).to receive(:exist?).with("Dangerfile.js").and_return(true)
      expect(subject.path_for_implicit_dangerfile).to eq("Dangerfile.js")
    end

    it "should raise if it cannot find a file" do
      subject = Danger::Executor.new
      allow(File).to receive(:exist?).with("Dangerfile").and_return(false)
      allow(File).to receive(:exist?).with("Dangerfile.rb").and_return(false)
      allow(File).to receive(:exist?).with("Dangerfile.js").and_return(false)
      expect { subject.path_for_implicit_dangerfile }.to raise_error SystemExit
    end
  end

  describe "choosing the  Dangerfile" do
    it "it creates a JS Dangerfile when given a JS filepath" do
      subject = Danger::Executor.new
      env = Danger::EnvironmentManager.new(stub_env)
      dm = subject.dangerfile_for_path("Dangerfile.js", env, testing_ui)
      expect(dm).to be_kind_of(Danger::DangerfileJS)
    end

    it "it creates a JS Dangerfile when given a any other path" do
      subject = Danger::Executor.new
      env = Danger::EnvironmentManager.new(stub_env)
      dm = subject.dangerfile_for_path("Dangerfile", env, testing_ui)
      expect(dm).to be_kind_of(Danger::Dangerfile)
    end
  end
end
