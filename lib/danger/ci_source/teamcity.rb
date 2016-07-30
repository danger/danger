module Danger
  # https://www.jetbrains.com/teamcity/

  ### CI Setup
  #
  # You need to go to your project settings. Then depending on the type of your build settings, you may need
  # to add a new build step for Danger. You want to be able to run the command `bundle exec danger`, so
  # the "Simple Command Runner" should be all you need to do that.
  #
  # ### Token + Environment Setup
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.
  #
  # However, you will need to find a way to add the environment vars: `GITHUB_REPO_SLUG`, `GITHUB_PULL_REQUEST_ID` and
  # `GITHUB_REPO_URL`. These are not added by default. You could do this via the GitHub API potentially.
  #
  # We would love some advice on improving this setup.
  #
  class TeamCity < CI
    def self.validates_as_ci?(env)
      env.key? "TEAMCITY_VERSION"
    end

    def self.validates_as_pr?(env)
      ["GITHUB_PULL_REQUEST_ID", "GITHUB_REPO_URL", "GITHUB_REPO_SLUG"].all? { |x| env[x] }
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      # NB: Unfortunately TeamCity doesn't provide these variables
      # automatically so you have to add these variables manually to your
      # project or build configuration
      self.repo_slug       = env["GITHUB_REPO_SLUG"]
      self.pull_request_id = env["GITHUB_PULL_REQUEST_ID"].to_i
      self.repo_url        = env["GITHUB_REPO_URL"]
    end
  end
end
