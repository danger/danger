require 'danger/danger_core/environment_manager'

describe Danger::Dangerfile::DSL do
  describe "#import" do
    before do
      file = make_temp_file("")
      @dm = Danger::Dangerfile.new
      @dm.env = Danger::EnvironmentManager.new({ "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true", "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane", "TRAVIS_PULL_REQUEST" => "12" })
      @dm.parse(file.path)
    end

    describe "#import_local" do
      it "supports exact paths" do
        @dm.import("spec/fixtures/plugins/example_exact_path.rb")

        expect { @dm.example_exact_path }.to_not raise_error
        expect(@dm.example_exact_path.echo).to eq("Hi there exact")
      end

      it "supports file globbing" do
        @dm.import("spec/fixtures/plugins/*globbing*.rb")

        expect(@dm.example_globbing.echo).to eq("Hi there globbing")
      end

      # This is going to become a lot more complicated in the future, so I'm
      # happy to have it pending for now.
      xit "raises an error when calling a plugin that's not a subclass of Plugin" do
        @dm.import("spec/fixtures/plugins/example_broken.rb")

        expect do
          @dm.example_broken
        end.to raise_error("'example_broken' is not a valid danger plugin".red)
      end
    end

    describe "#import_url" do
      it "downloads a remote .rb file" do
        expect { @dm.example_remote.echo }.to raise_error NoMethodError

        url = "https://krausefx.com/example_remote"
        stub_request(:get, "https://krausefx.com/example_remote.rb").
          to_return(status: 200, body: File.read("spec/fixtures/plugins/example_remote.rb"))

        @dm.import(url)

        expect(@dm.example_remote.echo).to eq("Hi there remote 🎉")
      end

      it "rejects unencrypted plugins" do
        expect do
          @dm.import("http://unecnrypted.org")
        end.to raise_error("URL is not https, for security reasons `danger` only supports encrypted requests")
      end
    end
  end
end
