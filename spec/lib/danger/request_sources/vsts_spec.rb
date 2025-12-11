# frozen_string_literal: true

require "danger/request_sources/vsts"

RSpec.describe Danger::RequestSources::VSTS, host: :vsts do
  let(:env) { stub_env }
  let(:subject) { Danger::RequestSources::VSTS.new(stub_ci, env) }

  describe "#new" do
    it "should not raise uninitialized constant error" do
      expect { described_class.new(stub_ci, env) }.not_to raise_error
    end
  end

  describe "#host" do
    it "sets the host specified by `DANGER_VSTS_HOST`" do
      expect(subject.host).to eq("https://example.visualstudio.com/example")
    end
  end

  describe "#validates_as_api_source" do
    it "validates_as_api_source for non empty `DANGER_VSTS_API_TOKEN`" do
      expect(subject.validates_as_api_source?).to be true
    end
  end

  describe "#pr_json" do
    before do
      stub_pull_request
      subject.fetch_details
    end

    it "has a non empty pr_json after `fetch_details`" do
      expect(subject.pr_json).to be_truthy
    end

    describe "#pr_json[:pullRequestId]" do
      it "has fetched the same pull request id as ci_sources's `pull_request_id`" do
        expect(subject.pr_json[:pullRequestId]).to eq(1)
      end
    end

    describe "#pr_json[:title]" do
      it "has fetched the pull requests title" do
        expect(subject.pr_json[:title]).to eq("This is a danger test")
      end
    end
  end

  describe "#no_danger_comments" do
    before do
      stub_get_comments_request_no_danger
    end

    it "has to post a new comment" do
      allow(subject).to receive(:post_new_comment)
      expect(subject).to receive(:post_new_comment)
      subject.update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false)
    end
  end

  describe "#danger_comment_update" do
    before do
      stub_get_comments_request_with_danger
    end

    it "it has to update the previous comment" do
      allow(subject).to receive(:update_old_comment)
      expect(subject).to receive(:update_old_comment)
      subject.update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger", new_comment: false)
    end
  end

  describe "valid server response" do
    before do
      stub_pull_request
      subject.fetch_details
    end

    it "sets its pr_json" do
      expect(subject.pr_json).to be_truthy
    end

    describe "status message" do
      it "Shows a success message when no errors/warnings" do
        message = subject.generate_description(warnings: [], errors: [])
        expect(message).to start_with("All green.")
      end

      it "Shows an error messages when there are errors" do
        message = subject.generate_description(warnings: violations_factory([1, 2, 3]), errors: [])
        expect(message).to eq("⚠️ 3 Warnings. Don't worry, everything is fixable.")
      end

      it "Shows an error message when errors and warnings" do
        message = subject.generate_description(warnings: violations_factory([1, 2]), errors: violations_factory([1, 2, 3]))
        expect(message).to eq("⚠️ 3 Errors. 2 Warnings. Don't worry, everything is fixable.")
      end

      it "Deals with singualars in messages when errors and warnings" do
        message = subject.generate_description(warnings: violations_factory([1]), errors: violations_factory([1]))
        expect(message).to eq("⚠️ 1 Error. 1 Warning. Don't worry, everything is fixable.")
      end
    end

    describe "inline issues" do
      before do
        stub_get_comments_request_with_danger
        subject.fetch_details
      end

      it "adds new comments inline" do
        expect(subject.client).to receive(:post_inline_comment).with(anything, "CHANGELOG.md", 4)
        expect(subject.client).to receive(:update_comment).with(142, 1, anything)

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 4)
        subject.update_pull_request!(warnings: [], errors: [], messages: [v])
      end

      it "crosses out sticky comments" do
        expect(subject.client).to receive(:post_inline_comment).with(anything, "CHANGELOG.md", 4)
        expect(subject.client).to receive(:update_comment).with(142, 1, anything)

        m = Danger::Markdown.new("Sure thing", "CHANGELOG.md", 4)
        subject.update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [m])
      end
    end
  end
end
