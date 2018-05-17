# https://circleci.com/docs/environment-variables
require "uri"
require "danger/ci_source/circle_api"
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # For setting up CircleCI, we recommend turning on "Only build pull requests" in "Advanced Settings." Without this enabled,
  # it's trickier for Danger to determine whether you're in a pull request or not, as the environment metadata
  # isn't as reliable.
  #
  # A common scenario is when CircleCI begins building a commit before the commit becomes associated with a PR
  # (e.g. a developer pushes their branch to the remote repo for the first time. CircleCI spins up and begins building.
  # Moments later the developer creates a PR on GitHub. Since the build process started before the PR existed,
  # Danger won't be able to use the Circle-provided environment variables to retrieve PR metadata.)
  #
  # With "Only build pull requests" enabled, you can add `bundle exec danger` to your `config.yml` (Circle 2.0).
  #
  # e.g.
  #
  #  ``` yaml
  #  - run: bundle exec danger --verbose
  #  ```
  #
  # And that should be it!
  #
  # ### Token Setup
  #
  # If "Only build pull requests" can't be enabled for your project, Danger _can_ still work by relying on CircleCI's API
  # to retrieve PR metadata, which will require an API token.
  #
  # 1. Go to your project > Settings > API Permissions. Create a token with scope "view-builds" and a label like "DANGER_CIRCLE_CI_API_TOKEN".
  # 2. Settings > Environement Variables. Add the token as a CircleCI environment variable, which exposes it to the Danger process.
  #
  # There is no difference here for OSS vs Closed, both scenarios will need this environment variable.
  #
  # With these pieces in place, Danger should be able to work as expected.
  #
  class CircleCI < CI
    # Side note: CircleCI is complicated. The env vars for PRs are not guaranteed to exist
    # if the build was triggered from a commit, to look at examples of the different types
    # of CI states, see this repo: https://github.com/orta/show_circle_env

    def self.validates_as_ci?(env)
      env.key? "CIRCLE_BUILD_NUM"
    end

    def self.validates_as_pr?(env)
      # This will get used if it's available, instead of the API faffing.
      return true if env["CI_PULL_REQUEST"] && !env["CI_PULL_REQUEST"].empty?
      return true if env["CIRCLE_PULL_REQUEST"] && !env["CIRCLE_PULL_REQUEST"].empty?

      # Real-world talk, it should be worrying if none of these are in the environment
      return false unless ["DANGER_CIRCLE_CI_API_TOKEN", "CIRCLE_PROJECT_USERNAME", "CIRCLE_PROJECT_REPONAME", "CIRCLE_BUILD_NUM"].all? { |x| env[x] && !env[x].empty? }

      # Uses the Circle API to determine if it's a PR otherwise
      api = CircleAPI.new
      api.pull_request?(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub, Danger::RequestSources::BitbucketCloud]
    end

    def initialize(env)
      self.repo_url = env["CIRCLE_REPOSITORY_URL"]
      pr_url = env["CI_PULL_REQUEST"] || env["CIRCLE_PULL_REQUEST"]

      # If it's not a real URL, use the Circle API
      unless pr_url && URI.parse(pr_url).kind_of?(URI::HTTP)
        api = CircleAPI.new
        pr_url = api.pull_request_url(env)
      end

      # We should either have got it via the API, or
      # an ENV var.
      pr_path = URI.parse(pr_url).path.split("/")
      if pr_path.count == 5
        # The first one is an extra slash, ignore it
        self.repo_slug = pr_path[1] + "/" + pr_path[2]
        self.pull_request_id = pr_path[4]

      else
        message = "Danger::Circle.rb considers this a PR, " \
                  "but did not get enough information to get a repo slug" \
                  "and PR id.\n\n" \
                  "PR path: #{pr_url}\n" \
                  "Keys: #{env.keys}"
        raise message.red
      end
    end
  end
end
