require "danger/request_sources/vsts_api"

RSpec.describe Danger::RequestSources::VSTSAPI, host: :vsts do
  describe "#inspect" do
    it "masks personal access token on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_VSTS_API_TOKEN") { "supertopsecret" }
      api = described_class.new("danger", "danger", 1, stub_env)

      inspected = api.inspect

      expect(inspected).to include(%(@token="********"))
    end

    it "handles http hosts" do
      env = stub_env
      env["DANGER_VSTS_HOST"] = "http://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.pr_api_endpoint).to eq("http://my_url/_apis/git/repositories/danger/pullRequests/1")
      env["DANGER_VSTS_HOST"] = "my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.pr_api_endpoint).to eq("https://my_url/_apis/git/repositories/danger/pullRequests/1")
    end

    it "checks uses ssl only for https urls" do
      env = stub_env
      env["DANGER_VSTS_HOST"] = "http://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.send(:use_ssl)).to eq(false)

      env["DANGER_VSTS_HOST"] = "https://my_url"
      api = described_class.new("danger", "danger", 1, env)
      expect(api.send(:use_ssl)).to eq(true)
    end
  end
end
