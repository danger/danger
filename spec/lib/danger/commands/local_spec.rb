require "danger/commands/local"
require "octokit"

RSpec.describe Danger::Local do
  describe ".options" do
    it "contains extra options for local command" do
      result = described_class.options

      expect(result).to include ["--use-merged-pr=[#id]", "The ID of an already merged PR inside your history to use as a reference for the local run."]
      expect(result).to include ["--clear-http-cache", "Clear the local http cache before running Danger locally."]
      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
    end
  end

  context "default options" do
    it "pr number is nil and clear_http_cache defaults to false" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result.instance_variable_get(:"@pr_num")).to eq nil
      expect(result.instance_variable_get(:"@clear_http_cache")).to eq false
    end
  end

  describe "it" do

    it "informs the user and runs the dangerfile" do
      github = double(:host => "github.com", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "1337"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = Danger::Something.new(dangerfile, ui)

      subject.do(false) { ui.puts "success" }
      expect(ui.string).to include("Running your Dangerfile against this PR - https://github.com/danger/danger/pull/1337")
      expect(ui.string).to include("success")
    end

    it "exits when no applicable ci source was identified" do
      dangerfile = FakeDangerfile.new(FakeEnv.new(nil), false)
      ui = testing_ui
      subject = Danger::Something.new(dangerfile, ui)

      expect { subject.do(false) { ui.puts "success" } }.to raise_error(SystemExit)
      expect(ui.string).to include("only works with GitHub")
      expect(ui.string).not_to include("success")
    end

    it "turns on verbose if arguments wasn't passed" do
      github = double(:host => "", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "123"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = Danger::Something.new(dangerfile, ui)

      subject.do(false) {}
      expect(ui.string).to include("Turning on --verbose")
    end

    it "does not evaluate Dangerfile if local repo was not found on github" do
      github = double(:host => "", :support_tokenless_auth= => nil)
      allow(github).to receive(:fetch_details).and_raise(Octokit::NotFound.new)
      env = FakeEnv.new(FakeCiSource.new("danger/danger", "123"), github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = Danger::Something.new(dangerfile, ui)

      subject.do(true) { ui.puts "success" }
      expect(ui.string).to include("was not found on GitHub")
      expect(ui.string).not_to include("success")
    end
  end
end

class FakeDangerfile < Struct.new(:env, :verbose)
end

class FakeEnv < Struct.new(:ci_source, :request_source)
end

class FakeCiSource < Struct.new(:repo_slug, :pull_request_id)
end
