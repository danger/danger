# https://www.jetbrains.com/teamcity/
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # You need to go to your project settings. Then depending on the type of your build settings, you may need
  # to add a new build step for Danger. You want to be able to run the command `bundle exec danger`, so
  # the "Simple Command Runner" should be all you need to do that.
  #
  # ### Token + Environment Setup
  #
  # #### GitHub
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.
  #
  # However, you will need to find a way to add the environment vars: `GITHUB_REPO_SLUG`, `GITHUB_PULL_REQUEST_ID` and
  # `GITHUB_REPO_URL`. These are not added by default. You can manually add `GITHUB_REPO_SLUG` and `GITHUB_REPO_URL`
  #  as build parameters or by exporting them inside your Simple Command Runner.
  #
  # As for `GITHUB_PULL_REQUEST_ID`, TeamCity provides the `%teamcity.build.branch%` variable which is in the format
  # `PR_NUMBER/merge`. You can slice the Pull Request ID out by doing the following:
  #
  # ```sh
  # branch="%teamcity.build.branch%"
  # export GITHUB_PULL_REQUEST_ID=(${branch//\// })
  # ```
  #
  # #### GitLab
  #
  # As this is self-hosted, you will need to add the `DANGER_GITLAB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITLAB_API_TOKEN="123" bundle exec danger`.
  #
  # However, you will need to find a way to add the environment vars: `GITLAB_REPO_SLUG`, `GITLAB_PULL_REQUEST_ID` and
  # `GITLAB_REPO_URL`. These are not added by default. You could do this via the GitLab API potentially.
  #
  # We would love some advice on improving this setup.
  #
  class TeamCity < CI
    class << self
      def validates_as_github_pr?(env)
        ["GITHUB_PULL_REQUEST_ID", "GITHUB_REPO_URL"].all? { |x| env[x] && !env[x].empty? }
      end

      def validates_as_gitlab_pr?(env)
        ["GITLAB_REPO_SLUG", "GITLAB_PULL_REQUEST_ID", "GITLAB_REPO_URL"].all? { |x| env[x] && !env[x].empty? }
      end
    end

    def self.validates_as_ci?(env)
      env.key? "TEAMCITY_VERSION"
    end

    def self.validates_as_pr?(env)
      validates_as_github_pr?(env) || validates_as_gitlab_pr?(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::GitLab]
    end

    def initialize(env)
      # NB: Unfortunately TeamCity doesn't provide these variables
      # automatically so you have to add these variables manually to your
      # project or build configuration

      if self.class.validates_as_github_pr?(env)
        extract_github_variables!(env)
      elsif self.class.validates_as_gitlab_pr?(env)
        extract_gitlab_variables!(env)
      end
    end

    private

    def extract_github_variables!(env)
      self.repo_slug       = env["GITHUB_REPO_SLUG"]
      self.pull_request_id = env["GITHUB_PULL_REQUEST_ID"].to_i
      self.repo_url        = env["GITHUB_REPO_URL"]
    end

    def extract_gitlab_variables!(env)
      self.repo_slug       = env["GITLAB_REPO_SLUG"]
      self.pull_request_id = env["GITLAB_PULL_REQUEST_ID"].to_i
      self.repo_url        = env["GITLAB_REPO_URL"]
    end
  end
end
