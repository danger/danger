# coding: utf-8

RSpec.describe Danger::DangerfileBitbucketServerPlugin, host: :bitbucket_server do
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
        expect(plugin.pr_title).to eq("This is a danger test")
      end
    end

    describe "#pr_author" do
      it "has a fetched author" do
        expect(plugin.pr_author).to eq("a.user")
      end
    end

    describe "#pr_link" do
      it "has a fetched link to it self" do
        expect(plugin.pr_link).to eq("https://stash.example.com/projects/IOS/repos/fancyapp/pull-requests/2080")
      end
    end

    describe "#branch_for_base" do
      it "has a fetched branch for base" do
        expect(plugin.branch_for_base).to eq("develop")
      end
    end

    describe "#branch_for_head" do
      it "has a fetched branch for head" do
        expect(plugin.branch_for_head).to eq("feature/Danger")
      end
    end

    describe "#base_commit" do
      it "has a fetched base commit" do
        expect(plugin.base_commit).to eq("b366c9564ad57786f0e5c6b8333c7aa1e2e90b9a")
      end
    end

    describe "#head_commit" do
      it "has a fetched head commit" do
        expect(plugin.head_commit).to eq("c50b3f61e90dac6a00b7d0c92e415a4348bb280a")
      end
    end

    describe "#html_link" do
      it "creates a usable html link" do
        skip "Atlassian disabled inline HTML support for Bitbucket Server"

        expect(plugin.html_link("Classes/Main Categories/Feed/FeedViewController.m")).to include(
          "<a href='https://stash.example.com/projects/IOS/repos/fancyapp/browse/Classes/Main%20Categories/Feed/FeedViewController.m?at=c50b3f61e90dac6a00b7d0c92e415a4348bb280a'>Classes/Main Categories/Feed/FeedViewController.m</a>"
        )
      end

      it "handles #XX line numbers in the same format a the other plugins" do
        skip "Atlassian disabled inline HTML support for Bitbucket Server"

        expect(plugin.html_link("Classes/Main Categories/Feed/FeedViewController.m#100")).to include(
          "<a href='https://stash.example.com/projects/IOS/repos/fancyapp/browse/Classes/Main%20Categories/Feed/FeedViewController.m?at=c50b3f61e90dac6a00b7d0c92e415a4348bb280a#100'>Classes/Main Categories/Feed/FeedViewController.m</a>"
        )
      end
    end

    describe "#markdown_link" do
      it "creates a usable markdown link" do
        expect(plugin.markdown_link("Classes/Main Categories/Feed/FeedViewController.m")).to include(
          "[Classes/Main Categories/Feed/FeedViewController.m](https://stash.example.com/projects/IOS/repos/fancyapp/browse/Classes/Main%20Categories/Feed/FeedViewController.m?at=c50b3f61e90dac6a00b7d0c92e415a4348bb280a)"
        )
      end
    end
  end
end
