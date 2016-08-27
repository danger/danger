# coding: utf-8

module Danger
  describe DangerfileBitbucketServerPlugin, host: :bitbucket_server do
    let(:dangerfile) { testing_dangerfile }
    let(:plugin) { described_class.new(dangerfile) }
    
    before do
      stub_pull_request
    end
    
    describe "plugin" do
      before do
        dangerfile.env.request_source.fetch_details
      end

      it "it has the pr_json" do
        expect(plugin.pr_json).to be_truthy
      end

      it "it has a title" do
        expect(plugin.pr_title).to eql("This is a danger test")
      end

      it "it has a author slug" do
        expect(plugin.pr_author).to eql("a.user")
      end
    end
  end
end
