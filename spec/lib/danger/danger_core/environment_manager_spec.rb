require "danger/danger_core/environment_manager"

RSpec.describe Danger::EnvironmentManager, use: :ci_helper do
  describe ".local_ci_source" do
    it "loads Bamboo" do
      with_bamboo_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Bamboo
      end
    end

    it "loads Bitrise" do
      with_bitrise_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Bitrise
      end
    end

    it "loads Buildkite" do
      with_buildkite_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Buildkite
      end
    end

    it "loads Circle" do
      with_circle_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::CircleCI
      end
    end

    it "loads Drone" do
      with_drone_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Drone
      end
    end

    it "loads GitLab CI" do
      with_gitlabci_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::GitLabCI
      end
    end

    it "loads Jenkins (Github)" do
      with_jenkins_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Jenkins
      end
    end

    it "loads Jenkins (Gitlab)" do
      with_jenkins_setup_gitlab_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Jenkins
      end
    end

    it "loads Jenkins (Gitlab v3)" do
      with_jenkins_setup_gitlab_v3_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Jenkins
      end
    end

    it "loads Local Git Repo" do
      with_localgitrepo_setup do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::LocalGitRepo
      end
    end

    it "loads Screwdriver" do
      with_screwdriver_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Screwdriver
      end
    end

    it "loads Semaphore" do
      with_semaphore_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Semaphore
      end
    end

    it "loads Surf" do
      with_surf_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Surf
      end
    end

    it "loads TeamCity" do
      with_teamcity_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::TeamCity
      end
    end

    it "loads Travis" do
      with_travis_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Travis
      end
    end

    it "loads Xcode Server" do
      with_xcodeserver_setup_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::XcodeServer
      end
    end

    it "does not return a CI source with no ENV deets" do
      we_dont_have_ci_setup do |system_env|
        expect(Danger::EnvironmentManager.local_ci_source(system_env)).to eq nil
      end
    end
  end

  describe ".pr?" do
    it "loads Bamboo" do
      with_bamboo_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Bitrise" do
      with_bitrise_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Buildkite" do
      with_buildkite_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Circle" do
      with_circle_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Drone" do
      with_drone_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads GitLab CI" do
      with_gitlabci_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Jenkins (Github)" do
      with_jenkins_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Jenkins (Gitlab)" do
      with_jenkins_setup_gitlab_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Jenkins (Gitlab v3)" do
      with_jenkins_setup_gitlab_v3_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Local Git Repo" do
      with_localgitrepo_setup do |system_env|
        expect(described_class.pr?(system_env)).to eq(false)
      end
    end

    it "loads Screwdriver" do
      with_screwdriver_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Semaphore" do
      with_semaphore_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Surf" do
      with_surf_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads TeamCity" do
      with_teamcity_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Travis" do
      with_travis_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Xcode Server" do
      with_xcodeserver_setup_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "does not return a CI source with no ENV deets" do
      env = { "KEY" => "VALUE" }

      expect(Danger::EnvironmentManager.local_ci_source(env)).to eq nil
    end
  end

  describe ".danger_head_branch" do
    it "returns danger_head" do
      expect(described_class.danger_head_branch).to eq("danger_head")
    end
  end

  describe ".danger_base_branch" do
    it "returns danger_base" do
      expect(described_class.danger_base_branch).to eq("danger_base")
    end
  end

  describe "#pr?" do
    it "returns true if has a ci source" do
      with_travis_setup_and_is_a_pull_request(request_source: :github) do |env|
        env_manager = Danger::EnvironmentManager.new(env, testing_ui)
        expect(env_manager.pr?).to eq true
      end
    end
  end

  describe "#danger_id" do
    it "returns the default identifier when none is provided" do
      with_travis_setup_and_is_a_pull_request(request_source: :github) do |env|
        env_manager = Danger::EnvironmentManager.new(env, testing_ui)
        expect(env_manager.danger_id).to eq("danger")
      end
    end

    it "returns the identifier user by danger" do
      with_travis_setup_and_is_a_pull_request(request_source: :github) do |env|
        env_manager = Danger::EnvironmentManager.new(env, testing_ui, "test_identifier")
        expect(env_manager.danger_id).to eq("test_identifier")
      end
    end
  end

  def git_repo_with_danger_branches_setup
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `git remote add origin git@github.com:devdanger/devdanger.git`
        `touch README.md`
        `git add .`
        `git commit -q -m "Initial Commit"`
        `git checkout -q -b danger_head`
        `git commit -q --allow-empty -m "HEAD"`
        head_sha = `git rev-parse HEAD`.chomp![0..6]
        `git checkout -q master`
        `git checkout -q -b danger_base`
        `git commit -q --allow-empty -m "BASE"`
        base_sha = `git rev-parse HEAD`.chomp![0..6]
        `git checkout -q master`

        yield(head_sha, base_sha)
      end
    end
  end

  describe "#clean_up" do
    it "delete danger branches" do
      git_repo_with_danger_branches_setup do |_, _|
        with_travis_setup_and_is_a_pull_request(request_source: :github) do |system_env|
          described_class.new(system_env, testing_ui).clean_up

          branches = `git branch`.lines.map(&:strip!)

          expect(branches).not_to include("danger_head")
          expect(branches).not_to include("danger_base")
        end
      end
    end
  end

  describe "#meta_info_for_head" do
    it "returns last commit of danger head branch" do
      git_repo_with_danger_branches_setup do |head_sha, _base_sha|
        with_travis_setup_and_is_a_pull_request(request_source: :github) do |env|
          result = described_class.new(env, testing_ui).meta_info_for_head

          expect(result).to include(head_sha)
        end
      end
    end
  end

  describe "#meta_info_for_base" do
    it "returns last commit of danger base branch" do
      git_repo_with_danger_branches_setup do |_head_sha, base_sha|
        with_travis_setup_and_is_a_pull_request(request_source: :github) do |env|
          result = described_class.new(env, testing_ui).meta_info_for_base

          expect(result).to include(base_sha)
        end
      end
    end
  end

  it "stores travis in the source" do
    number = 123
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane",
            "TRAVIS_PULL_REQUEST" => number.to_s }
    danger_em = Danger::EnvironmentManager.new(env, testing_ui)

    expect(danger_em.ci_source.pull_request_id).to eq(number.to_s)
  end

  it "stores circle in the source" do
    number = 800
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "CIRCLE_BUILD_NUM" => "true",
            "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/#{number}",
            "CIRCLE_PROJECT_USERNAME" => "orta",
            "CIRCLE_PROJECT_REPONAME" => "thing" }
    danger_em = Danger::EnvironmentManager.new(env, testing_ui)

    expect(danger_em.ci_source.pull_request_id).to eq(number.to_s)
  end

  it "creates a GitHub attr" do
    env = { "DANGER_GITHUB_API_TOKEN" => "abc123",
            "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane",
            "TRAVIS_PULL_REQUEST" => 123.to_s }
    danger_em = Danger::EnvironmentManager.new(env, testing_ui)

    expect(danger_em.request_source).to be_truthy
  end

  it "skips push runs and only runs for pull requests" do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }

    expect(Danger::EnvironmentManager.local_ci_source(env)).to be_truthy
    expect(Danger::EnvironmentManager.pr?(env)).to eq(false)
  end

  it "uses local git repo and github when running locally" do
    env = { "DANGER_USE_LOCAL_GIT" => "true" }
    danger_em = Danger::EnvironmentManager.new(env, testing_ui)

    expect(danger_em.ci_source).to be_truthy
    expect(danger_em.request_source).to be_truthy
  end

  context "Without API tokens" do
    it "handles providing useful github info when the repo url is github" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      expect(ui.string).to include("For your GitHub repo, you need to expose: DANGER_GITHUB_API_TOKEN")
      expect(ui.string).to include("You may also need: DANGER_GITHUB_HOST, DANGER_GITHUB_API_BASE_URL")
    end

    it "handles providing useful gitlab info when the repo url is gitlab" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)
      danger_em.ci_source.repo_url = "https://gitlab.com/danger-systems/danger.systems"

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      expect(ui.string).to include("For your GitLab repo, you need to expose: DANGER_GITLAB_API_TOKEN")
    end

    it "handles providing useful bitbucket info when the repo url is bitbuckety" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)
      danger_em.ci_source.repo_url = "https://bitbucket.org/ios/fancyapp"

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      expect(ui.string).to include("For your BitbucketCloud repo, you need to expose: DANGER_BITBUCKETCLOUD_USERNAME, DANGER_BITBUCKETCLOUD_UUID, DANGER_BITBUCKETCLOUD_PASSWORD")
    end

    it "handles throwing out all kinds of info when the repo url isnt recognised" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)
      danger_em.ci_source.repo_url = "https://orta.io/my/thing"

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      messages = [
        "For Danger to run on this project, you need to expose a set of following the ENV vars:",
        " - GitHub: DANGER_GITHUB_API_TOKEN",
        " - GitLab: DANGER_GITLAB_API_TOKEN",
        " - BitbucketServer: DANGER_BITBUCKETSERVER_USERNAME, DANGER_BITBUCKETSERVER_PASSWORD, DANGER_BITBUCKETSERVER_HOST",
        " - BitbucketCloud: DANGER_BITBUCKETCLOUD_USERNAME, DANGER_BITBUCKETCLOUD_UUID, DANGER_BITBUCKETCLOUD_PASSWORD"
      ]
      messages.each do |m|
        expect(ui.string).to include(m)
      end
    end

    it "includes all your env var keys" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true", "RANDO_KEY" => "secret" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)
      danger_em.ci_source.repo_url = "https://orta.io/my/thing"

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      expect(ui.string).to include("Found these keys in your ENV: DANGER_GITHUB_API_TOKEN, HAS_JOSH_K_SEAL_OF_APPROVAL, RANDO_KEY.")
    end

    it "prints travis note in subtitle" do
      req_src_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true", "RANDO_KEY" => "secret", "TRAVIS_SECURE_ENV_VARS" => "true" }
      ui = testing_ui
      danger_em = Danger::EnvironmentManager.new(req_src_env, ui)
      danger_em.ci_source.repo_url = "https://orta.io/my/thing"

      expect do
        danger_em.raise_error_for_no_request_source(req_src_env, ui)
      end.to raise_error(SystemExit)

      expect(ui.string).to include("Travis note: If you have an open source project, you should ensure 'Display value in build log' enabled for these flags, so that PRs from forks work.")
    end

    context "cannot find request source" do
      it "raises error" do
        env = { "DANGER_USE_LOCAL_GIT" => "true" }
        fake_ui = double("Cork::Board")
        allow(Cork::Board).to receive(:new) { fake_ui }
        allow(Danger::RequestSources::RequestSource).to receive(:available_request_sources) { [] }

        expect(fake_ui).to receive(:title)
        expect(fake_ui).to receive(:puts).exactly(5).times

        expect { Danger::EnvironmentManager.new(env, nil) }.to raise_error(SystemExit)
      end
    end
  end
end
