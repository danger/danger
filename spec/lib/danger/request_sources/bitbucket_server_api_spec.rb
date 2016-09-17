require "danger/request_sources/bitbucket_server_api"

describe Danger::RequestSources::BitbucketServerAPI, host: :bitbucket_server do
  describe "#inspect" do
    it "masks password on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETSERVER_PASSWORD") { "supertopsecret" }
      api = described_class.new("danger", "danger", 1, stub_env)

      inspected = api.inspect

      expect(inspected).to include(%(@password="********"))
    end
  end
end
