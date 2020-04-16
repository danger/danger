# coding: utf-8

require "danger/request_sources/bitbucket_cloud"

RSpec.describe Danger::RequestSources::BitbucketCloud, host: :bitbucket_cloud do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketCloud.new(stub_ci, env) }

  describe "#new" do
    it "should not raise uninitialized constant error" do
      expect { described_class.new(stub_ci, env) }.not_to raise_error
    end
  end

  describe "#validates_as_api_source" do
    subject { bs.validates_as_api_source? }

    context "when DANGER_BITBUKETCLOUD_USERNAME, _UUID, and _PASSWORD are set" do
      it { is_expected.to be_truthy }
    end

    context "when DANGER_BITBUCKETCLOUD_USERNAME is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_USERNAME" } }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_USERNAME is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_USERNAME" => "") }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_UUID" } }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_UUID" => "") }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_PASSWORD is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_PASSWORD" } }

      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_PASSWORD is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_PASSWORD" => "") }
      it { is_expected.to be_falsey }
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
        expect(bs.pr_json[:title]).to eq("This is a danger test for bitbucket cloud")
      end
    end
  end
end
