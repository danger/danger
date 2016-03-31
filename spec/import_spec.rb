describe Danger::Dangerfile::DSL do
  describe "#import" do
    before do
      file = make_temp_file("")
      @dm = Danger::Dangerfile.new
      @dm.parse(file.path)
    end

    describe "#import_local" do
      it "supports exact paths" do
        plugin_name = "ExampleExactPath"
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(false)
        expect(@dm.import("spec/fixtures/plugins/example_exact_path.rb")).to eq(["spec/fixtures/plugins/example_exact_path.rb"])
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(true)
        expect(Danger::Dangerfile::DSL.const_get(plugin_name)).to eq(Danger::Dangerfile::DSL::ExampleExactPath)

        expect(@dm.example_exact_path).to eq("Hi there exact 🎉")
      end

      it "supports file globbing" do
        plugin_name = "ExampleGlobbing"
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(false)
        expect(@dm.import("spec/fixtures/plugins/*globbing*.rb")).to eq(["spec/fixtures/plugins/example_globbing.rb"])
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(true)
        expect(Danger::Dangerfile::DSL.const_get(plugin_name)).to eq(Danger::Dangerfile::DSL::ExampleGlobbing)

        expect(@dm.example_globbing).to eq("Hi there globbing 🎉")
      end

      it "raises an error when calling a plugin that's not a subclass of action" do
        plugin_name = "ExampleBroken"
        expect(@dm.import("spec/fixtures/plugins/example_broken.rb")).to eq(["spec/fixtures/plugins/example_broken.rb"])
        expect(Danger::Dangerfile::DSL.const_get(plugin_name)).to eq(Danger::Dangerfile::DSL::ExampleBroken)

        expect do
          @dm.example_broken
        end.to raise_error("'example_broken' is not a valid danger plugin".red)
      end
    end

    describe "#import_url" do
      it "downloads a remote .rb file" do
        url = "https://krausefx.com/example_remote"
        stub_request(:get, "https://krausefx.com/example_remote.rb").
          to_return(status: 200, body: File.read("spec/fixtures/plugins/example_remote.rb"))

        plugin_name = "ExampleRemote"
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(false)
        expect(@dm.import(url).last).to end_with("/temporary_remote_action.rb") # fixed name when downloading
        expect(Danger::Dangerfile::DSL.const_defined?(plugin_name)).to eq(true)
        expect(Danger::Dangerfile::DSL.const_get(plugin_name)).to eq(Danger::Dangerfile::DSL::ExampleRemote)

        expect(@dm.example_remote).to eq("Hi there remote 🎉")
      end

      it "rejects unencrypted plugins" do
        expect do
          @dm.import("http://unecnrypted.org")
        end.to raise_error("URL is not https, for security reasons `danger` only supports encrypted requests")
      end
    end
  end
end
