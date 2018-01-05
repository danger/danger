require "danger/request_sources/bitbucket_cloud_api"

RSpec.describe Danger::RequestSources::BitbucketCloudAPI, host: :bitbucket_cloud do
  describe "#inspect" do
    it "masks password on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETCLOUD_PASSWORD") { "supertopsecret" }
      api = described_class.new("danger/danger", 1, nil, stub_env)

      inspected = api.inspect

      expect(inspected).to include(%(@password="********"))
    end
  end

  describe "#project" do
    it "gets set from repo_slug" do
      api = described_class.new("org/repo", 1, nil, stub_env)

      expect(api.project).to eq("org")
    end
  end

  describe "#slug" do
    it "gets set from repo_slug" do
      api = described_class.new("org/repo", 1, nil, stub_env)

      expect(api.slug).to eq("repo")
    end
  end

  describe "#fetch_pr_id" do
    it "gets called if pull_request_id is nil" do
      stub_pull_requests
      api = described_class.new("ios/fancyapp", nil, "feature_branch", stub_env)

      expect(api.pull_request_id).to eq(2080)
    end
  end
end
