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
        expect(described_class.should_submit?(review, Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE, "super body")).to be false
      end
    end

    context "when submission body is different to review body" do
      let (:submissions_body) { "submission body" }

      before do
        allow(review).to receive(:body).and_return "unique body"
      end

      context "when want to approve pr" do
        let (:submission_event) { Danger::RequestSources::GitHubSource::Review::EVENT_APPROVE }

        context "when review is pending" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_PENDING }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review is approved" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_APPROVED }
          end

          it "returns false" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be false
          end
        end

        context "when review has request changes" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_REQUESTED_CHANGES }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review is commented" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_COMMENTED }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end
      end

      context "when want to request changes for pr" do
        let (:submission_event) { Danger::RequestSources::GitHubSource::Review::EVENT_REQUEST_CHANGES }

        context "when review is pending" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_PENDING }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review is approved" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_APPROVED }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review has request changes" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_REQUESTED_CHANGES }
          end

          it "returns false" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be false
          end
        end

        context "when review is commented" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_COMMENTED }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end
      end

      context "when want to comment pr" do
        let (:submission_event) { Danger::RequestSources::GitHubSource::Review::EVENT_COMMENT }

        context "when review is pending" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_PENDING }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review is approved" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_APPROVED }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review has request changes" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_REQUESTED_CHANGES }
          end

          it "returns true" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be true
          end
        end

        context "when review is commented" do
          before do
            allow(review).to receive(:status) { Danger::RequestSources::GitHubSource::Review::STATUS_COMMENTED }
          end

          it "returns false" do
            expect(described_class.should_submit?(review, submission_event, submissions_body)).to be false
          end
        end
      end
    end
  end
end
