require "danger/danger_core/executor"

# If you cannot find a method, please check spec/support/ci_helper.rb.
RSpec.describe Danger::Executor, use: :ci_helper do
  describe "#validate!" do
    context "with CI + is a PR" do
      it "not raises error on Bamboo" do
        with_bamboo_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Bitrise" do
        with_bitrise_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Buildkite" do
        with_buildkite_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Circle" do
        with_circle_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Codefresh" do
        with_codefresh_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Drone" do
        with_drone_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on GitLab CI" do
        with_gitlabci_setup_and_is_a_merge_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Jenkins (GitHub)" do
        with_jenkins_setup_github_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Jenkins (GitLab)" do
        with_jenkins_setup_gitlab_and_is_a_merge_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Jenkins (GitLab v3)" do
        with_jenkins_setup_gitlab_v3_and_is_a_merge_request do |system_env|
          expect { described_class.new(system_env).validate!(testing_ui) }.not_to raise_error
        end
      end

      it "not raises error on Local Git Repo" do
        with_localgitrepo_setup do |system_env|
          ui = testing_ui
          expect { described_class.new(system_env).validate!(ui) }.to raise_error(SystemExit)
          expect(ui.string).to include("Not a LocalGitRepo Pull Request - skipping `danger` run")
        end
      end

      it "not raises error on Screwdriver" do
        with_screwdriver_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on Semaphore" do
        with_semaphore_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on Surf" do
        with_surf_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on TeamCity (GitLab)" do
        with_teamcity_setup_github_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on TeamCity (GitLab)" do
        with_teamcity_setup_gitlab_and_is_a_merge_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on Travis" do
        with_travis_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end

      it "not raises error on Xcode Server" do
        with_xcodeserver_setup_and_is_a_pull_request do |system_env|
          expect { described_class.new(system_env) }.not_to raise_error
        end
      end
    end

    context "without CI" do
      it "raises error with clear message" do
        we_dont_have_ci_setup do |system_env|
          expect { described_class.new(system_env).run }.to \
            raise_error(SystemExit, /Could not find the type of CI for Danger to run on./)
        end
      end
    end

    context "NOT a PR" do
      it "exits with clear message" do
        not_a_pull_request do |system_env|
          ui = testing_ui
          expect { described_class.new(system_env).validate!(ui) }.to raise_error(SystemExit)
          expect(ui.string).to include("Not a Travis Pull Request - skipping `danger` run")
        end
      end

      it "raises error on GitLab CI" do
        with_gitlabci_setup_and_is_not_a_merge_request do |system_env|
          ui = testing_ui
          expect { described_class.new(system_env).validate!(ui) }.to raise_error(SystemExit)
          expect(ui.string).to include("Not a GitLabCI Merge Request - skipping `danger` run")
        end
      end
    end
  end

  context "a test for SwiftWeekly #89" do
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
end
