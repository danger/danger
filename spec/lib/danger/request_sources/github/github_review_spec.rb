require "danger/request_sources/github/github_review"

RSpec.describe Danger::RequestSources::GitHubSource::Review do
  let(:client) { double(Octokit::Client) }

  describe "submit" do
    subject do
      Danger::RequestSources::GitHubSource::Review.new(client, stub_ci)
    end

    context "when there are messages" do
      before do
        subject.start
        subject.message("Hi")
      end

      it "approves the pr" do
        expect(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, anger::RequestSources::GitHubSource::Review::EVENT_APPROVE, anything)
        subject.submit
      end
    end

    it "suggests changes to the pr" do
      allow(client).to receive(:create_pull_request_review).with(stub_ci.repo_slug, stub_ci.pull_request_id, )
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
        expect(subject.status).to eq ""
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
        expect(subject.id).to eq 15629060
      end
    end

    describe "status" do
      it "returns a status from request review json" do
        expect(subject.status).to eq Danger::RequestSources::GitHubSource::Review::STATUS_APPROVED
      end
    end

    describe "body" do
      it "returns a body from request review json" do
        expect(subject.status).to eq "Looks good"
      end
    end
  end
end
