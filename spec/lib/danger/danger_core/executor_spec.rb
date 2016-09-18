require "danger/danger_core/executor"

class FakeProse
  attr_accessor :ignored_words

  def lint_files
    true
  end

  def check_spelling
    true
  end
end

module Danger
  class Dangerfile
    def prose
      FakeProse.new
    end
  end
end


describe Danger::Executor do
  let!(:spec_root) { Dir.pwd }

  def pretend_we_are_in_the_travis
    approval = ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"]
    pr = ENV["TRAVIS_PULL_REQUEST"]
    slug = ENV["TRAVIS_REPO_SLUG"]
    api_token = ENV["DANGER_GITHUB_API_TOKEN"]

    ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"] = "true"
    ENV["TRAVIS_PULL_REQUEST"] = "42"
    ENV["TRAVIS_REPO_SLUG"] = "danger/danger"
    ENV["DANGER_GITHUB_API_TOKEN"] = "1234567890"*4

    yield
  ensure
    ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"] = approval
    ENV["TRAVIS_PULL_REQUEST"] = pr
    ENV["TRAVIS_REPO_SLUG"] = slug
    api_token = api_token
  end

  def to_json(raw)
    JSON.parse raw
  end

  def swiftweekly_pr_89_as_json
    to_json IO.read("#{spec_root}/spec/fixtures/github/swiftweekly.github.io-pulls-89.json")
  end

  def swiftweekly_issues_89_as_json
    to_json IO.read("#{spec_root}/spec/fixtures/github/swiftweekly.github.io-issues-89.json")
  end

  def swiftweekly_issue_89_comments_as_json
    to_json IO.read("#{spec_root}/spec/fixtures/github/swiftweekly.github.io-issues-89-comments.json")
  end

  before do
    fake_client = double("Octokit::Client")
    allow(Octokit::Client).to receive(:new) { fake_client }
    allow(fake_client).to receive(:pull_request) { swiftweekly_pr_89_as_json }
    allow(fake_client).to receive(:get) { swiftweekly_issues_89_as_json }
    allow(fake_client).to receive(:issue_comments) { swiftweekly_issue_89_comments_as_json }
    allow(fake_client).to receive(:delete_comment) { true }
    allow(fake_client).to receive(:create_status) { true }
  end

  it "works please" do
    Dir.chdir "spec/fixtures/github/swiftweekly.github.io" do |dir|
      pretend_we_are_in_the_travis do
        Danger::Executor.new(ENV).run(
          dangerfile_path: "Dangerfile"
        )
      end
    end
  end
end
