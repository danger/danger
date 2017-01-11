require "danger/request_sources/github/github_review_resolver"
require "danger/request_sources/github/github_review"

RSpec.describe Danger::GitHub::ReviewResolver do
  let(:review) { double("Danger::GitHub::Review") }
  subject { Danger::GitHub::ReviewResolver.new(review) }

  describe "should_submit?" do
    context "when review status is pending" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_PENDING }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_false
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_false
        end
      end
    end

    context "when review status is requested changes" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_REQUESTED_CHANGES }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_true
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_true
        end
      end
    end

    context "when review status is approved" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_APPROVED }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_false
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_false
        end
      end
    end
  end

  describe "should_create?" do
    context "when review status is pending" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_PENDING }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_true
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_true
        end
      end
    end

    context "when review status is requested changes" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_REQUESTED_CHANGES }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_false
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_false
        end
      end
    end

    context "when review status is approved" do
      before do
        allow(review).to receive(:status) { Danger::GitHub::Review::STATUS_APPROVED }
      end

      context "when wants to approve" do
        it "returns false" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_APPROVE)).to be_false
        end
      end

      context "when wants to request changes" do
        it "returns true" do
          expect(subject.should_create?(Danger::GitHub::Review::EVENT_REQUEST_CHANGES)).to be_true
        end
      end
    end
  end
end
