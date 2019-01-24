require "danger/ci_source/support/pull_request_finder"

RSpec.describe Danger::PullRequestFinder do
  def finder(pull_request_id: "", logs: nil, repo_slug: "danger/danger", remote: "false", remote_url: "")
    described_class.new(
      pull_request_id,
      repo_slug,
      remote: remote,
      git_logs: logs,
      remote_url: remote_url
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
      IO.read("spec/fixtures/ci_source/support/danger_danger_pr_518.json"),
      object_class: OpenStruct
    )
  end

  describe "#new" do
    it "translates $remote into boolean" do
      expect(finder(remote: "true")).to have_instance_variables(
        "@remote" => true
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
        allow(client).to receive(:pull_request).with("danger/danger", "518") do
          open_pull_requests_info
        end

        result = finder(pull_request_id: "518", logs: "not important here", remote: "true").call

        expect(result.pull_request_id).to eq "518"
        expect(result.head).to eq "pr 518 head commit sha1"
        expect(result.base).to eq "pr 518 base commit sha1"
      end
    end

    context "specify api endpoint of octokit client" do
      it "By DANGER_GITHUB_API_HOST" do
        ENV["DANGER_GITHUB_API_HOST"] = "https://enterprise.artsy.net"

        allow(Octokit::Client).to receive(:new).with(
          access_token: ENV["DANGER_GITHUB_API_TOKEN"],
          api_endpoint: "https://enterprise.artsy.net"
        ) { spy("Octokit::Client") }

        finder(pull_request_id: "42", remote: true, logs: "not important").call
      end

      it "fallbacks to DANGER_GITHUB_API_BASE_URL" do
        ENV["DANGER_GITHUB_API_BASE_URL"] = "https://enterprise.artsy.net"

        allow(Octokit::Client).to receive(:new).with(
          access_token: ENV["DANGER_GITHUB_API_TOKEN"],
          api_endpoint: "https://enterprise.artsy.net"
        ) { spy("Octokit::Client") }

        finder(pull_request_id: "42", remote: true, logs: "not important").call
      end
    end
  end

  describe "#find_scm_provider" do

  def find_scm_provider(url)
    finder(remote: "true").send(:find_scm_provider, url)
  end

    it "detects url for bitbucket cloud" do
      url = "https://bitbucket.org/ged/ruby-pg/pull-requests/42"
      expect(find_scm_provider(url)).to eq :bitbucket_cloud
    end

    it "detects url for bitbucket server" do
      url = "https://example.com/bitbucket/projects/Test/repos/test/pull-requests/1946"
      expect(find_scm_provider(url)).to eq :bitbucket_server
    end

    it "detects url for bitbucket github" do
      url = "http://www.github.com/torvalds/linux/pull/42"
      expect(find_scm_provider(url)).to eq :github
    end

    it "defaults to github when unknown url" do
      url = "http://www.default-url.com/"
      expect(find_scm_provider(url)).to eq :github
    end

  end

end
