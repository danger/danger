module Command
  describe Danger::Runner do
    describe "Calls Executor" do
      it "works without parameters" do
        a = "fake"
        expect(Danger::Executor).to receive(:new).and_return(a)
        expect(a).to receive(:run).with({
          base: nil,
          head: nil,
          dangerfile_path: "Dangerfile",
          danger_id: "danger",
          verbose: nil
        })
        Danger::Runner.run([])
      end
    end

    describe "finding a Dangerfile" do
      it "should add a plugin to the dangerfile plugins array" do
        subject = Danger::Runner
        allow(File).to receive(:exist?).with("Dangerfile").and_return(true)

        expect(subject.path_for_implicit_dangerfile).to eq("Dangerfile")
      end

      it "should add a plugin to the dangerfile plugins array" do
        subject = Danger::Runner
        allow(File).to receive(:exist?).with("Dangerfile").and_return(false)
        allow(File).to receive(:exist?).with("Dangerfile.rb").and_return(false)
        allow(File).to receive(:exist?).with("Dangerfile.js").and_return(true)
        expect(subject.path_for_implicit_dangerfile).to eq("Dangerfile.js")
      end

      it "should raise if it cannot find a file" do
        subject = Danger::Runner
        allow(File).to receive(:exist?).with("Dangerfile").and_return(false)
        allow(File).to receive(:exist?).with("Dangerfile.rb").and_return(false)
        allow(File).to receive(:exist?).with("Dangerfile.js").and_return(false)
        expect { subject.path_for_implicit_dangerfile }.to raise_error SystemExit
      end
    end
  end
end
