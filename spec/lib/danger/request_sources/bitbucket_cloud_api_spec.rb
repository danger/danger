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

    context "with access token" do
      let(:env) do
        stub_env.merge(
          "DANGER_BITBUCKETCLOUD_OAUTH_KEY" => "XXX",
          "DANGER_BITBUCKETCLOUD_OAUTH_SECRET" => "YYY"
        )
      end
      before { stub_access_token }

      it "masks access_token on inspect" do
        inspected = api.inspect

        expect(inspected).to include(%(@access_token="********"))
      end
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

  describe "#credentials_given?" do
    subject { api.credentials_given? }

    context "when UUID is not given" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_UUID" } }

      it { is_expected.to be_falsy }
    end

    context "when username is not given" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_USERNAME" } }

      it { is_expected.to be_falsy }
    end

    context "when password is not given" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_PASSWORD" } }

      it { is_expected.to be_falsy }
    end

    context "when repository access token is given" do
      let(:env) do
        stub_env
          .reject { |k, _| %w[DANGER_BITBUCKETCLOUD_USERNAME DANGER_BITBUCKETCLOUD_PASSWORD].include?(k) }
          .merge("DANGER_BITBUCKETCLOUD_REPO_ACCESSTOKEN" => "xxx")
      end

      it { is_expected.to be_truthy }
    end

    it "#fetch_json raise error when missing credentials" do
      empty_env = {}
      expect { api.pull_request }.to raise_error WebMock::NetConnectNotAllowedError
    end

    it "#post raise error when missing credentials" do
      empty_env = {}
      expect { api.post("http://post-url.org", {}) }.to raise_error NoMethodError
    end

    it "#delete raise error when missing credentials" do
      empty_env = {}
      expect { api.delete("http://delete-url.org") }.to raise_error NoMethodError
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
