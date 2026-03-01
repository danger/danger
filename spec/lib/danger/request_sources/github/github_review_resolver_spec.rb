require "danger/request_sources/github/github_review_resolver"
require "danger/request_sources/github/github_review"

RSpec.describe Danger::RequestSources::GitHubSource::ReviewResolver do
  let(:review) { double(Danger::RequestSources::GitHubSource::Review) }

  describe "should_submit?" do
    context "when submission body the same as review has" do
      before do
        allow(review).to receive(:body).and_return "super body"
      end

      it "returns false" do
        expect(described_class.should_submit?(review, "super body")).to be false
      end
    end

    context "when submission body is different to review body" do
      let(:submission_body) { "submission body" }

      before do
        allow(review).to receive(:body).and_return "unique body"
      end

      it "returns true" do
        expect(described_class.should_submit?(review, "super body")).to be true
      end
    end
  end
end
