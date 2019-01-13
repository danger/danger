# coding: utf-8

RSpec.describe Danger::DangerfileBitbucketCloudPlugin, host: :bitbucket_cloud do
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
        expect(plugin.pr_title).to eq("This is a danger test for bitbucket cloud")
      end
    end

    describe "#pr_author" do
      it "has a fetched author" do
        expect(plugin.pr_author).to eq("AName")
      end
    end

    describe "#pr_link" do
      it "has a fetched link to it self" do
        expect(plugin.pr_link).to eq("https://api.bitbucket.org/2.0/repositories/ios/fancyapp/pullrequests/2080")
      end
    end

    describe "#branch_for_base" do
      it "has a fetched branch for base" do
        expect(plugin.branch_for_base).to eq("develop")
      end
    end

    describe "#branch_for_head" do
      it "has a fetched branch for head" do
        expect(plugin.branch_for_head).to eq("develop")
      end
    end

    describe "#base_commit" do
      it "has a fetched base commit" do
        expect(plugin.base_commit).to eq("9c823062cf99")
      end
    end

    describe "#head_commit" do
      it "has a fetched head commit" do
        expect(plugin.head_commit).to eq("b6f5656b6ac9")
      end
    end

  end
end
