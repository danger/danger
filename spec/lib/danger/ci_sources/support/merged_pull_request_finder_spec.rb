require "danger/ci_source/support/merged_pull_request_finder"

describe Danger::MergedPullRequestFinder do
  def finder(pull_request_id: "", logs: nil)
    described_class.new(
      pull_request_id,
      logs
    )
  end

  def merge_pull_request_log
    IO.read("spec/fixtures/ci_source/support/danger-git.log")
  end

  def squash_and_merge_log
    IO.read("spec/fixtures/ci_source/support/swiftweekly.github.io-git.log")
  end

  def two_kinds_of_merge_log
    IO.read("spec/fixtures/ci_source/support/two-kinds-of-merge-both-present.log")
  end

  describe "#call" do
    context "not specified Pull Request ID" do
      context "merge pull request type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          pull_request_id, sha = finder(logs: merge_pull_request_log).call

          expect(pull_request_id).to eq "557"
          expect(sha).to eq "bde9ea7"
        end
      end

      context "squash and merge type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          pull_request_id, sha = finder(logs: squash_and_merge_log).call

          expect(pull_request_id).to eq "89"
          expect(sha).to eq "129045f"
        end
      end
    end

    context "specify Pull Request ID" do
      context "merge pull request type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          pull_request_id, sha = finder(pull_request_id: "556", logs: merge_pull_request_log).call

          expect(pull_request_id).to eq "556"
          expect(sha).to eq "0cd9198"
        end
      end

      context "squash and merge type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          pull_request_id, sha = finder(pull_request_id: "77", logs: squash_and_merge_log).call

          expect(pull_request_id).to eq "77"
          expect(sha).to eq "3f7047a"
        end
      end
    end

    context "merged and squash-and-merged both present" do
      it "returns the most recent one" do
        pull_request_id, sha = finder(pull_request_id: "2", logs: two_kinds_of_merge_log).call

        expect(pull_request_id).to eq "2"
        expect(sha).to eq "9f8c75a"
      end
    end
  end
end
