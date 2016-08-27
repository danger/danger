# coding: utf-8
require "danger/request_source/request_source"

describe Danger::RequestSources::BitbucketServer, host: :bitbucket_server do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketServer.new(stub_ci, env) }
  
  describe "the bitbucket server host" do
    it "allows the set the host" do
      expect(bs.host).to eql("stash.example.com")
    end

    it "creates the pull request api URL" do
      expect(bs.pr_api_endpoint).to eql("https://stash.example.com/rest/api/1.0/projects/ios/repos/fancyapp/pull-requests/2080")
    end

    it "validates as api source" do
      expect(bs.validates_as_api_source?).to be true
    end
  end

  describe "valid server response" do
    before do
      stub_pull_request
    end

    it "sets its pr_json" do
      bs.fetch_details
      expect(bs.pr_json).to be_truthy
      expect(bs.pr_json[:id]).to eql(2080)
      expect(bs.pr_json[:title]).to eql("This is a danger test")
    end
  end
end
