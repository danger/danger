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

  describe "#pull_request_id" do
    it "gets set from pull_request_id" do
      api = described_class.new("org/repo", 1, nil, stub_env)

      expect(api.pull_request_id).to eq(1)
    end
  end

  describe "#host" do
    it "gets set from host" do
      api = described_class.new("org/repo", 1, nil, stub_env)

      expect(api.host).to eq("https://bitbucket.org/")
    end
  end
  
  describe "#credentials_given" do
    it "#fetch_json raise error when missing credentials" do
      empty_env = {}
      api = described_class.new("ios/fancyapp", "123", nil, empty_env)
      expect { api.pull_request }.to raise_error
    end

    it "#post raise error when missing credentials" do
      empty_env = {}
      api = described_class.new("ios/fancyapp", "123", nil, empty_env)
      expect { api.post("http://post-url.org", {}) }.to raise_error
    end

    it "#delete raise error when missing credentials" do
      empty_env = {}
      api = described_class.new("ios/fancyapp", "123", nil, empty_env)
      expect { api.delete("http://delete-url.org") }.to raise_error
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
