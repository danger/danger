describe Danger::Executor do
  describe "#run" do
    it "aborts when not in a ci env" do
      env = {}
      expect { Danger::Executor.new(env).run }
        .to raise_error(SystemExit)
        .and output(/Could not find the type of CI/).to_stderr
    end
  end
end
