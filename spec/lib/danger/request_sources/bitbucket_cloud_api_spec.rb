require "danger/request_sources/bitbucket_cloud_api"

RSpec.describe Danger::RequestSources::BitbucketCloudAPI, host: :bitbucket_cloud do
  subject(:api) { described_class.new(repo, pr_id, branch, env) }
  let(:repo) { "ios/fancyapp" }
  let(:pr_id) { 1 }
  let(:branch) { "feature_branch" }
  let(:env) { stub_env }

  describe "#inspect" do
    it "masks password on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETCLOUD_PASSWORD") { "supertopsecret" }
      inspected = api.inspect

      expect(inspected).to include(%(@password="********"))
    end
  end

  describe "#project" do
    let(:repo) { "org/repo" }

    it "gets set from repo_slug" do
      expect(api.project).to eq("org")
    end
  end

  describe "#slug" do
    let(:repo) { "org/repo" }

    it "gets set from repo_slug" do
      expect(api.slug).to eq("repo")
    end
  end

  describe "#pull_request_id" do

    it "gets set from pull_request_id" do
      expect(api.pull_request_id).to eq(1)
    end

    context "when pr_id is nil" do
      let(:pr_id) { nil }

      it "fetches the id from bitbucket" do
        stub_pull_requests
        expect(api.pull_request_id).to eq(2080)
      end
    end
  end

  describe "#host" do
    it "gets set from host" do
      expect(api.host).to eq("https://bitbucket.org/")
    end
  end

  describe "#my_uuid" do
    subject { api.my_uuid }
    let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_UUID" => uuid) }

    context "when DANGER_BITBUCKETCLOUD_UUID is empty string" do
      let(:uuid) { nil }

      it { is_expected.to be nil }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is empty string" do
      let(:uuid) { "" }

      it { is_expected.to eq "" }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is uuid without braces" do
      let(:uuid) { "c91be865-efc6-49a6-93c5-24e1267c479b" }

      it { is_expected.to eq "{c91be865-efc6-49a6-93c5-24e1267c479b}" }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is uuid with braces" do
      let(:uuid) { "{c91be865-efc6-49a6-93c5-24e1267c479b}" }

      it { is_expected.to eq "{c91be865-efc6-49a6-93c5-24e1267c479b}" }
    end
  end

  describe "#credentials_given" do
    it "#fetch_json raise error when missing credentials" do
      empty_env = {}
      expect { api.pull_request }.to raise_error
    end

    it "#post raise error when missing credentials" do
      empty_env = {}
      expect { api.post("http://post-url.org", {}) }.to raise_error
    end

    it "#delete raise error when missing credentials" do
      empty_env = {}
      expect { api.delete("http://delete-url.org") }.to raise_error
    end
  end

  describe "#fetch_access_token" do
    let(:pr_id) { "123" }
    let(:branch) { "feature_branch" }
    subject { api.access_token }

    context "when DANGER_BITBUCKET_CLOUD_OAUTH_KEY and _SECRET are set" do
      let(:env) do
        stub_env.merge(
          "DANGER_BITBUCKETCLOUD_OAUTH_KEY" => "XXX",
          "DANGER_BITBUCKETCLOUD_OAUTH_SECRET" => "YYY"
        )
      end
      before { stub_access_token }

      it { is_expected.to eq("a_token") }
    end

    context "when only DANGER_BITBUCKETCLOUD_OAUTH_KEY is set" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_OAUTH_KEY" => "XXX") }
      before { stub_access_token }

      it { is_expected.to be nil }
    end

    context "when neither DANGER_BITBUCKETCLOUD_OAUTH_KEY and _SECRET are set" do
      it { is_expected.to be nil }
    end
  end
end
