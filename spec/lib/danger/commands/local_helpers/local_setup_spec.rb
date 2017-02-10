require "octokit"

RSpec.describe Danger::LocalSetup do
  describe "#setup" do
    it "informs the user and runs the block" do
      github = double(:host => "github.com", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "1337"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(false) { ui.puts "success" }
      expect(ui.string).to include("Running your Dangerfile against this PR - https://github.com/danger/danger/pull/1337")
      expect(ui.string).to include("success")
    end

    it "exits when no applicable ci source was identified" do
      dangerfile = FakeDangerfile.new(FakeEnv.new(nil), false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      expect { subject.setup(false) { ui.puts "success" } }.to raise_error(SystemExit)
      expect(ui.string).to include("only works with GitHub")
      expect(ui.string).not_to include("success")
    end

    it "turns on verbose if arguments wasn't passed" do
      github = double(:host => "", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "123"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(false) {}
      expect(ui.string).to include("Turning on --verbose")
    end

    it "does not evaluate Dangerfile if local repo was not found on github" do
      github = double(:host => "", :support_tokenless_auth= => nil)
      allow(github).to receive(:fetch_details).and_raise(Octokit::NotFound.new)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "123"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(true) { ui.puts "success" }
      expect(ui.string).to include("was not found on GitHub")
      expect(ui.string).not_to include("success")
    end
  end

  class FakeDangerfile < Struct.new(:env, :verbose)
  end

  class FakeEnv < Struct.new(:ci_source, :request_source)
  end

  class FakeCiSource < Struct.new(:repo_slug, :pull_request_id)
  end
end
