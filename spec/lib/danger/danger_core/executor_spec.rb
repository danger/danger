describe Danger::Executor do
  describe "#run" do
    it "aborts when not in a ci env" do
      env = {}
      expect { Danger::Executor.new(env).run }
        .to raise_error(SystemExit)
        .and output(/Could not find the type of CI/).to_stderr
    end

    it "does not run Dangerfile when in ci env but no pr was identified" do
      env = { "DANGER_USE_LOCAL_GIT" => "true" }
      cork = double

      expect(cork).to receive(:puts)
      expect(Danger::Dangerfile).not_to receive(:new)

      Danger::Executor.new(env).run(cork: cork)
    end
  end

  describe "#post_results" do
    it "invokes update_pull_request! on request source" do
      request_source = double("Danger::RequestSources::GitHub")
      danger_file = spy("Dangerfile")
      danger_id = "orta"
      allow(danger_file).to receive_message_chain(:env, :request_source) do
        request_source
      end

      expect(request_source).to receive(:update_pull_request!)

      described_class.new({}).post_results(danger_file, danger_id)
    end
  end
end
