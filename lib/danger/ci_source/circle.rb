# https://circleci.com/docs/environment-variables
require "uri"
require "danger/ci_source/circle_api"
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # For setting up Circle CI, we recommend turning on "Only Build pull requests." in "Advanced Setting." Without this enabled,
  # it is _really_ tricky for Danger to know whether you are in a pull request or not, as the environment metadata
  # isn't reliable.
  #
  # With that set up, you can you add `bundle exec danger` to your `circle.yml`. If you override the default
  # `test:` section, then add it as an extra step. Otherwise add a new `pre` section to the test:
  #
  #  ``` ruby
  #   test:
  #     override:
  #        - bundle exec danger
  #  ```
  #
  # ### Token Setup
  #
  # There is no difference here for OSS vs Closed, add your `DANGER_GITHUB_API_TOKEN` to the Environment variable settings page.
  #
  # ### I still want to run commit builds
  #
  # OK, alright. So, if you add a `DANGER_CIRCLE_CI_API_TOKEN` then Danger will use the Circle API to look up
  # the status of whether a commit is inside a PR or not. You can generate a token from inside the project set_trace_func
  # then go to Permissions > "API Permissions" and generate a token with access to Status. Take that token and add
  # it to Build Settings > "Environment Variables".
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

      # Real-world talk, it should be worrying if none of these are in the environment
      return false unless ["CIRCLE_CI_API_TOKEN", "CIRCLE_PROJECT_USERNAME", "CIRCLE_PROJECT_REPONAME", "CIRCLE_BUILD_NUM"].all? { |x| env[x] && !env[x].empty? }

      # Uses the Circle API to determine if it's a PR otherwise
      api = CircleAPI.new
      api.pull_request?(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_url = env["CIRCLE_REPOSITORY_URL"]
      pr_url = env["CI_PULL_REQUEST"]

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
