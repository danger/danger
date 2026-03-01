require "octokit"

RSpec.describe Danger::LocalSetup do
  let(:ci_source) { FakeCiSource.new("danger/danger", "1337") }

  describe "#setup" do
    it "informs the user and runs the block" do
      github = double(:host => "github.com", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(ci_source, github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(verbose: false) { ui.puts "evaluated" }
      expect(ui.string).to include("Running your Dangerfile against this PR - https://github.com/danger/danger/pull/1337")
      expect(ui.string).to include("evaluated")
    end

    it "exits when no applicable ci source was identified" do
      dangerfile = FakeDangerfile.new(FakeEnv.new(nil, nil), false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      expect do
        subject.setup(verbose: false) { ui.puts "evaluated" }
      end.to raise_error(SystemExit)
      expect(ui.string).to include("only works with GitHub")
      expect(ui.string).not_to include("evaluated")
    end

    it "turns on verbose if arguments wasn't passed" do
      github = double(:host => "", :support_tokenless_auth= => nil, :fetch_details => nil)
      env = FakeEnv.new(ci_source, github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(verbose: false) {}
      expect(ui.string).to include("Turning on --verbose")
    end

    it "does not evaluate Dangerfile if local repo wasn't found on github" do
      github = double(:host => "", :support_tokenless_auth= => nil)
      allow(github).to receive(:fetch_details).and_raise(Octokit::NotFound.new)
      env = FakeEnv.new(ci_source, github)
      dangerfile = FakeDangerfile.new(env, false)
      ui = testing_ui
      subject = described_class.new(dangerfile, ui)

      subject.setup(verbose: true) { ui.puts "evaluated" }
      expect(ui.string).to include("was not found on GitHub")
      expect(ui.string).not_to include("evaluated")
    end
  end

  class FakeDangerfile
    attr_reader :env
    attr_accessor :verbose

    def initialize(env, verbose)
      @env = env
      @verbose = verbose
    end
  end

  class FakeEnv
    attr_reader :ci_source, :request_source

    def initialize(ci_source, request_source)
      @ci_source = ci_source
      @request_source = request_source
    end
  end

  class FakeCiSource
    attr_reader :repo_slug, :pull_request_id

    def initialize(repo_slug, pull_request_id)
      @repo_slug = repo_slug
      @pull_request_id = pull_request_id
    end
  end
end
