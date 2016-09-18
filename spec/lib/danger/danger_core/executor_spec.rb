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
  let!(:project_root) { Dir.pwd }

  def prepare_fake_swiftweekly_repository(dir)
    head_sha = base_sha = nil

    Dir.chdir dir do
      `echo "# SwiftWeekly" >> README.md`
      `mkdir _drafts _posts`
      FileUtils.cp "#{project_root}/spec/fixtures/github/Dangerfile", dir
      `git init`
      `git add .`
      `git commit -m "first commit"`
      `git remote add origin git@github.com:SwiftWeekly/swiftweekly.github.io.git`

      # Create 2016-09-15-issue-38.md
      `git checkout -b jp-issue-38 --quiet`
      IO.write("_drafts/2016-09-15-issue-38.md", "init 2016-09-15-issue-38.md")
      `git add _drafts/2016-09-15-issue-38.md`
      `git commit -m "flesh out issue 38 based on suggestions from #75, #79"`

      # Update 2016-09-15-issue-38.md
      IO.write("_drafts/2016-09-15-issue-38.md", "update 2016-09-15-issue-38.md")
      `git add _drafts/2016-09-15-issue-38.md`
      `git commit -m "address first round of review feedback"`

      # Move 2016-09-15-issue-38.md from _drafts/ to _posts/
      `git mv _drafts/2016-09-15-issue-38.md _posts/2016-09-15-issue-38.md`
      `git add .`
      `git commit -m "move issue 38 to _posts"`

      shas = `git log --oneline`.scan(/\b[0-9a-f]{5,40}\b/)
      head_sha = shas.first
      base_sha = shas.last
    end

    [head_sha, base_sha]
  end

  def pretend_we_are_in_the_travis
    approval = ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"]
    pr = ENV["TRAVIS_PULL_REQUEST"]
    slug = ENV["TRAVIS_REPO_SLUG"]
    api_token = ENV["DANGER_GITHUB_API_TOKEN"]

    ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"] = "true"
    ENV["TRAVIS_PULL_REQUEST"] = "42"
    ENV["TRAVIS_REPO_SLUG"] = "danger/danger"
    ENV["DANGER_GITHUB_API_TOKEN"] = "1234567890" * 4 # octokit token is of size 40

    yield
  ensure
    ENV["HAS_JOSH_K_SEAL_OF_APPROVAL"] = approval
    ENV["TRAVIS_PULL_REQUEST"] = pr
    ENV["TRAVIS_REPO_SLUG"] = slug
    api_token = api_token
  end

  def to_json(raw)
    JSON.parse(raw)
  end

  def swiftweekly_pr_89_as_json(head_sha, base_sha)
    pr_json = to_json(IO.read("#{project_root}/spec/fixtures/github/swiftweekly.github.io-pulls-89.json"))
    pr_json["base"]["sha"] = base_sha
    pr_json["head"]["sha"] = head_sha
    pr_json
  end

  def swiftweekly_issues_89_as_json
    to_json(IO.read("#{project_root}/spec/fixtures/github/swiftweekly.github.io-issues-89.json"))
  end

  def swiftweekly_issue_89_comments_as_json
    to_json(IO.read("#{project_root}/spec/fixtures/github/swiftweekly.github.io-issues-89-comments.json"))
  end

  it "works" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        head_sha, base_sha = prepare_fake_swiftweekly_repository(dir)

        fake_client = double("Octokit::Client")
        allow(Octokit::Client).to receive(:new) { fake_client }
        allow(fake_client).to receive(:pull_request) { swiftweekly_pr_89_as_json(head_sha, base_sha) }
        allow(fake_client).to receive(:get) { swiftweekly_issues_89_as_json }
        allow(fake_client).to receive(:issue_comments) { swiftweekly_issue_89_comments_as_json }
        allow(fake_client).to receive(:delete_comment) { true }
        allow(fake_client).to receive(:create_status) { true }

        pretend_we_are_in_the_travis do
          Danger::Executor.new(ENV).run(dangerfile_path: "Dangerfile")
        end
      end
    end
  end

  after do
    module Danger
      class Dangerfile
        undef_method :prose
      end
    end
  end
end
