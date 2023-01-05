require "danger/request_sources/bitbucket_server"

RSpec.describe Danger::RequestSources::BitbucketServer, host: :bitbucket_server do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketServer.new(stub_ci, env) }

  describe "#new" do
    it "should not raise uninitialized constant error" do
      expect { described_class.new(stub_ci, env) }.not_to raise_error
    end
  end

  describe "#host" do
    it "sets the host specified by `DANGER_BITBUCKETSERVER_HOST`" do
      expect(bs.host).to eq("https://stash.example.com")
    end
  end

  describe "#validates_as_api_source" do
    it "validates_as_api_source for non empty `DANGER_BITBUCKETSERVER_USERNAME` and `DANGER_BITBUCKETSERVER_PASSWORD`" do
      expect(bs.validates_as_api_source?).to be true
    end
  end

  describe "#pr_json" do
    before do
      stub_pull_request
      bs.fetch_details
    end

    it "has a non empty pr_json after `fetch_details`" do
      expect(bs.pr_json).to be_truthy
    end

    describe "#pr_json[:id]" do
      it "has fetched the same pull request id as ci_sources's `pull_request_id`" do
        expect(bs.pr_json[:id]).to eq(2080)
      end
    end

    describe "#pr_json[:title]" do
      it "has fetched the pull requests title" do
        expect(bs.pr_json[:title]).to eq("This is a danger test")
      end
    end
  end

  describe "#pr_diff" do
    it "has a non empty pr_diff after fetch" do
      stub_pull_request_diff
      bs.pr_diff
      expect(bs.pr_diff).to be_truthy
    end
  end

  describe "#main_violations_group" do
    before do
      stub_pull_request_diff
    end

    it "includes file specific messages outside the PR diff by default" do
      warning_in_diff = Danger::Violation.new("foo", false, "Gemfile", 3, type: :warning)
      warning_outside_of_diff = Danger::Violation.new("bar", false, "file.rb", 1, type: :warning)

      warnings = [
        warning_in_diff,
        warning_outside_of_diff
      ]
      expect(bs.main_violations_group(warnings: warnings)).to eq({
        warnings: [warning_outside_of_diff],
        errors: [],
        messages: [],
        markdowns: []
        })
    end

    it "dismisses messages outside the PR diff when env variable is set" do
      new_env = stub_env
      new_env.merge!({ "DANGER_BITBUCKETSERVER_DISMISS_OUT_OF_RANGE_MESSAGES" => "true" })
      inspected = Danger::RequestSources::BitbucketServer.new(stub_ci, new_env)

      warnings = [
        Danger::Violation.new("foo", false, "Gemfile", 3, type: :warning),
        Danger::Violation.new("bar", false, "file.rb", 1, type: :warning)
      ]
      expect(inspected.main_violations_group(warnings: warnings)).to eq({
        warnings: [],
        errors: [],
        messages: [],
        markdowns: []
        })
    end
  end

  describe "#find_position_in_diff" do
    before do
      stub_pull_request_diff
    end

    it "returns false when changes are not in the `pr_diff`" do
      expect(bs.find_position_in_diff?("file.rb", 1)).to be_falsy
    end

    it "returns true when changes are in included in the `pr_diff`" do
      expect(bs.find_position_in_diff?("Gemfile", 3)).to be_truthy
    end
  end
end
