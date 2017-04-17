# coding: utf-8

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
end
