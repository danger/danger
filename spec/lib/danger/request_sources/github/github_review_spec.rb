require "danger/request_sources/github/github_review"
require "danger/helpers/comments_helper"
require "danger/helpers/comment"

RSpec.describe Danger::RequestSources::GitHubSource::Review, host: :github do
  include Danger::Helpers::CommentsHelper

  let(:client) { double(Octokit::Client) }

  describe "submit" do
    subject do
      Danger::RequestSources::GitHubSource::Review.new(client, stub_ci)
    end

    before do
      subject.start
    end

    it "submits review request with correct body" do
      subject.message("Hi")
      subject.markdown("Yo")
      subject.warn("I warn you")
      subject.fail("This is bad, really bad")

      messages = [Danger::Violation.new("Hi", true)]
      warnings = [Danger::Violation.new("I warn you", true)]
      errors = [Danger::Violation.new("This is bad, really bad", true)]
      markdowns = [Danger::Markdown.new("Yo", true)]
      expected_body = generate_comment(warnings: warnings,
                                       errors: errors,
                                       messages: messages,
                                       markdowns: markdowns,
                                       previous_violations: parse_comment(""),
                                       danger_id: "danger",
                                       template: "github")

      expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_REQUEST_CHANGES, body: expected_body)
      subject.submit
    end

    context "when there are only messages" do
      before do
        subject.message("Hi")
      end

      it "approves the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE, body: anything)
        subject.submit
      end
    end

    context "when there are only markdowns" do
      before do
        subject.markdown("Hi")
      end

      it "approves the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE, body: anything)
        subject.submit
      end
    end

    context "when there are only warnings" do
      before do
        subject.warn("Hi")
      end

      it "approves the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE, body: anything)
        subject.submit
      end
    end

    context "when there are only errors" do
      before do
        subject.fail("Yo")
      end

      it "suggests changes to the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_REQUEST_CHANGES, body: anything)
        subject.submit
      end
    end

    context "when there are errors" do
      before do
        subject.message("Hi")
        subject.markdown("Yo")
        subject.warn("I warn you")
        subject.fail("This is bad, really bad")
      end

      it "suggests changes to the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_REQUEST_CHANGES, body: anything)
        subject.submit
      end
    end

    context "when there are no errors" do
      before do
        subject.message("Hi")
        subject.markdown("Yo")
        subject.warn("I warn you")
      end

      it "sapproves the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, event: Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE, body: anything)
        subject.submit
      end
    end
  end

  context "when initialized without review json" do
    subject do
      Danger::RequestSources::GitHubSource::Review.new(client, stub_ci)
    end

    describe "id" do
      it "nil" do
        expect(subject.id).to be nil
      end
    end

    describe "status" do
      it "returns a pending status" do
        expect(subject.status).to eq Danger::RequestSources::GitHubSource::Review::STATUS_PENDING
      end
    end

    describe "body" do
      it "returns an empty string" do
        expect(subject.body).to eq ""
      end
    end
  end

  context "when initialized with review json" do
    let(:review_json) { JSON.parse(fixture("github_api/pr_review_response")) }

    subject do
      Danger::RequestSources::GitHubSource::Review.new(client, stub_ci, review_json)
    end

    describe "id" do
      it "returns an id of request review" do
        expect(subject.id).to eq 15_629_060
      end
    end

    describe "status" do
      it "returns a status from request review json" do
        expect(subject.status).to eq Danger::RequestSources::GitHubSource::Review::STATUS_APPROVED
      end
    end

    describe "body" do
      it "returns a body from request review json" do
        expect(subject.body).to eq "Looks good"
      end
    end
  end
end
