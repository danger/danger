describe Danger::Executor do
  describe "#run" do
    it "aborts when not in a ci env" do
      expect { Danger::Executor.new.run }
        .to raise_error(SystemExit)
        .and output(/Could not find the type of CI/).to_stderr
    end
  end
end
