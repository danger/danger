require "danger/request_sources/bitbucket_server_api"

RSpec.describe Danger::RequestSources::BitbucketServerAPI, host: :bitbucket_server do
  describe "#inspect" do
    it "masks password on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETSERVER_PASSWORD") { "supertopsecret" }
      api = described_class.new("danger", "danger", 1, stub_env)

      inspected = api.inspect

      expect(inspected).to include(%(@password="********"))
    end

    it "handles http hosts" do
      env = stub_env
      env["DANGER_BITBUCKETSERVER_HOST"] = "http://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.pr_api_endpoint).to eq("http://my_url/rest/api/1.0/projects/danger/repos/danger/pull-requests/1")
      env["DANGER_BITBUCKETSERVER_HOST"] = "my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.pr_api_endpoint).to eq("https://my_url/rest/api/1.0/projects/danger/repos/danger/pull-requests/1")
    end

    it "checks uses ssl only for https urls" do
      env = stub_env
      env["DANGER_BITBUCKETSERVER_HOST"] = "http://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.send(:use_ssl)).to eq(false)

      env["DANGER_BITBUCKETSERVER_HOST"] = "https://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.send(:use_ssl)).to eq(true)
    end
    
    it "post build successful" do
        allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETSERVER_PASSWORD") { "supertopsecret" }
         stub_request(:post, "https://stash.example.com/rest/build-status/1.0/commits/04dede05fb802bf1e6c69782ae98592d29c03b80").
         with(:body => "{\"state\":\"SUCCESSFUL\",\"key\":\"danger\",\"url\":\"build_job_link\",\"description\":\"description\"}",
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Basic YS5uYW1lOmFfcGFzc3dvcmQ=', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
         to_return(:status => 204, :body => "", :headers => {})
        api = described_class.new("danger", "danger", 1, stub_env)
        changesetId = '04dede05fb802bf1e6c69782ae98592d29c03b80'
        response = api.update_pr_build_status("SUCCESSFUL",changesetId,"build_job_link", "description")
        expect(response).to eq(nil)
   end 
  end
end
