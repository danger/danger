# coding: utf-8
require "danger/request_source/request_source"

describe Danger::RequestSources::BitbucketServer do
  describe "the bitbucket server host" do
    it "allows the set the host" do
      bs_host = "stash.example.com"
      bs_env = { "DANGER_BITBUCKETSERVER_HOST" => bs_host }
      bs = Danger::RequestSources::BitbucketServer.new(stub_ci, bs_env)
      expect(bs.host).to eql(bs_host)
    end

    it "creates the pull request api URL" do
      bs_host = "stash.example.com"
      bs_env = { "DANGER_BITBUCKETSERVER_HOST" => bs_host }
      bs = Danger::RequestSources::BitbucketServer.new(stub_ci, bs_env)
      expect(bs.pr_api_endpoint).to eql("https://stash.example.com/rest/api/1.0/projects/artsy/repos/eigen/pull-requests/800")
    end

    it "validates as api source" do
      bs_host = "stash.example.com"
      bs_env = { "DANGER_BITBUCKETSERVER_USERNAME" => "a.name", "DANGER_BITBUCKETSERVER_PASSWORD" => "a_password" }
      bs = Danger::RequestSources::BitbucketServer.new(stub_ci, bs_env)
      expect(bs.validates_as_api_source?).to be true
    end
  end

  describe "valid server response" do
    before do
      bs_env = {
        "DANGER_BITBUCKETSERVER_USERNAME" => "a.name",
        "DANGER_BITBUCKETSERVER_PASSWORD" => "a_password",
        "DANGER_BITBUCKETSERVER_HOST" => "stash.example.com"
      }
      @bs = Danger::RequestSources::BitbucketServer.new(stub_ci, bs_env)
      pr_response = fixture("bitbucket_server_api/pr_response")
      http = double
      allow(Net::HTTP).to receive(:start).and_yield http
      allow(http).to receive(:request).with(an_instance_of(Net::HTTP::Get)).and_return(Net::HTTPResponse)
      allow(Net::HTTPResponse).to receive(:body).and_return(pr_response)
    end

    it "sets its pr_json" do
      @bs.fetch_details
      expect(@bs.pr_json).to be_truthy
      expect(@bs.pr_json[:id]).to eql(2080)
      expect(@bs.pr_json[:title]).to eql("This is a danger test")
    end
  end
end
