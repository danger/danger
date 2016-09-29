require "danger/danger_core/environment_manager"

describe Danger::EnvironmentManager do
  describe ".local_ci_source", use: :ci_helper do
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

    it "loads Jenkins" do
      with_jenkins_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::Jenkins
      end
    end

    it "loads Local Git Repo" do
      with_localgitrepo_setup do |system_env|
        expect(described_class.local_ci_source(system_env)).to eq Danger::LocalGitRepo
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
      env = { "KEY" => "VALUE" }

      expect(Danger::EnvironmentManager.local_ci_source(env)).to eq nil
    end
  end

  describe ".pr?", use: :ci_helper do
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

    it "loads Jenkins" do
      with_jenkins_setup_github_and_is_a_pull_request do |system_env|
        expect(described_class.pr?(system_env)).to eq(true)
      end
    end

    it "loads Local Git Repo" do
      with_localgitrepo_setup do |system_env|
        expect(described_class.pr?(system_env)).to eq(false)
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

      expect(ui.string).to include("For your BitbucketCloud repo, you need to expose: DANGER_BITBUCKETCLOUD_USERNAME, DANGER_BITBUCKETCLOUD_PASSWORD")
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
        " - BitbucketCloud: DANGER_BITBUCKETCLOUD_USERNAME, DANGER_BITBUCKETCLOUD_PASSWORD"
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
  end
end
