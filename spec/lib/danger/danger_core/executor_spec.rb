require "danger/danger_core/executor"

describe Danger::Executor do

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
