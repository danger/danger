# coding: utf-8

RSpec.describe Danger::DangerfileVSTSPlugin, host: :vsts do
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
        expect(plugin.pr_author).to eq("pierremarcairoldi")
      end
    end

    describe "#pr_link" do
      it "has a fetched link to it self" do
        expect(plugin.pr_link).to eq("https://petester42.visualstudio.com/_git/danger-test/pullRequest/1")
      end
    end

    describe "#branch_for_base" do
      it "has a fetched branch for base" do
        expect(plugin.branch_for_base).to eq("master")
      end
    end

    describe "#branch_for_head" do
      it "has a fetched branch for head" do
        expect(plugin.branch_for_head).to eq("feature/danger")
      end
    end

    describe "#base_commit" do
      it "has a fetched base commit" do
        expect(plugin.base_commit).to eq("b803d2daf56ec1d69c84902b2037b9b7dc089ac1")
      end
    end

    describe "#head_commit" do
      it "has a fetched head commit" do
        expect(plugin.head_commit).to eq("1e1dfca72160939ef1988c2669e11ef2861b3707")
      end
    end

    describe "#markdown_link" do
      it "creates a usable markdown link" do
        expect(plugin.markdown_link("Classes/Main Categories/Feed/FeedViewController.m")).to include(
          "[Classes/Main Categories/Feed/FeedViewController.m](https://petester42.visualstudio.com/_git/danger-test/commit/1e1dfca72160939ef1988c2669e11ef2861b3707?path=/Classes/Main%20Categories/Feed/FeedViewController.m&_a=contents)"
        )
      end
      it "creates a usable markdown link with line numbers" do
        expect(plugin.markdown_link("Classes/Main Categories/Feed/FeedViewController.m#L100")).to include(
          "[Classes/Main Categories/Feed/FeedViewController.m](https://petester42.visualstudio.com/_git/danger-test/commit/1e1dfca72160939ef1988c2669e11ef2861b3707?path=/Classes/Main%20Categories/Feed/FeedViewController.m&_a=contents&line=100)"
        )
      end
    end
  end
end
