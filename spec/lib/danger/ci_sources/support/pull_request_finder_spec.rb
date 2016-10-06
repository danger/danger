require "danger/ci_source/support/pull_request_finder"

RSpec.describe Danger::PullRequestFinder do
  def finder(pull_request_id: "", logs: nil, repo_slug: "danger/danger", check_open_pr: "false")
    described_class.new(
      pull_request_id,
      logs,
      repo_slug, # repo_slug
      check_open_pr # check_open_pr
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

  def open_pull_requests_info
    require "ostruct"
    JSON.parse(
      IO.read("spec/fixtures/ci_source/support/open-pull-requests.json"),
      object_class: OpenStruct
    )
  end

  describe "#new" do
    context "when needs to check Open PR" do
      it "raises if repo slug is not given" do
        expect { finder(repo_slug: nil, check_open_pr: "true") }.to \
          raise_error(
            RuntimeError,
            /danger pr requires a repository hosted on GitHub.com or GitHub Enterprise./
          )
      end
    end

    it "translates $check_open_pr into boolean" do
      expect(finder(check_open_pr: "true")).to have_instance_variables(
        "@need_to_check_open_pr" => true
      )
    end
  end

  describe "#call" do
    context "not specified Pull Request ID" do
      context "merge pull request type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          result = finder(logs: merge_pull_request_log).call

          expect(result.pull_request_id).to eq "557"
          expect(result.sha).to eq "bde9ea7"
        end
      end

      context "squash and merge type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          result = finder(logs: squash_and_merge_log).call

          expect(result.pull_request_id).to eq "89"
          expect(result.sha).to eq "129045f"
        end
      end
    end

    context "specify Pull Request ID" do
      context "merge pull request type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          result = finder(pull_request_id: "556", logs: merge_pull_request_log).call

          expect(result.pull_request_id).to eq "556"
          expect(result.sha).to eq "0cd9198"
        end
      end

      context "squash and merge type Pull Request" do
        it "returns correct Pull Request ID and SHA1" do
          result = finder(pull_request_id: "77", logs: squash_and_merge_log).call

          expect(result.pull_request_id).to eq "77"
          expect(result.sha).to eq "3f7047a"
        end
      end
    end

    context "merged and squash-and-merged both present" do
      it "returns the most recent one" do
        result = finder(pull_request_id: "2", logs: two_kinds_of_merge_log).call

        expect(result.pull_request_id).to eq "2"
        expect(result.sha).to eq "9f8c75a"
      end
    end

    context "with open Pull Request" do
      it "returns the opened Pull Request info" do
        client = double("Octokit::Client")
        allow(Octokit::Client).to receive(:new) { client }
        allow(client).to receive(:pull_requests) { open_pull_requests_info }

        result = finder(pull_request_id: "518", logs: "not important here", check_open_pr: "true").call

        expect(result.pull_request_id).to eq "518"
        expect(result.head).to eq "72cab59fa003b6c2127397b2aac4952d539825e4"
        expect(result.base).to eq "03a2b065143295525e9cdcb1e79d22b3cea09f94"
      end
    end
  end
end
