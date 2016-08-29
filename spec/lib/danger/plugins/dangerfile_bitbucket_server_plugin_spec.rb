# coding: utf-8

describe Danger::DangerfileBitbucketServerPlugin, host: :bitbucket_server do
  let(:dangerfile) { testing_dangerfile }
  let(:plugin) { described_class.new(dangerfile) }

  before do
    stub_pull_request
  end

  describe "plugin" do
    before do
      dangerfile.env.request_source.fetch_details
    end

    describe "#pr_json" do
      it "has a non empty json" do
        expect(plugin.pr_json).to be_truthy
      end
    end

    describe "#pr_title" do
      it "has a fetched title" do
        expect(plugin.pr_title).to eql("This is a danger test")
      end
    end

    describe "#pr_author" do
      it "has a fetched author" do
        expect(plugin.pr_author).to eql("a.user")
      end
    end
  end
end
