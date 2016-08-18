# https://circleci.com/docs/environment-variables
require "uri"
require "danger/ci_source/circle_api"

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
  class CircleCI < CI
    def self.validates_as_ci?(env)
      env.key? "CIRCLE_BUILD_NUM"
    end

    def self.validates_as_pr?(env)
      # This will get used if it's available, instead of the API faffing.
      return true unless env["CI_PULL_REQUEST"].empty?

      # Real-world talk, it should be worrying if none of these are in the environment
      return false unless ["CIRCLE_CI_API_TOKEN", "CIRCLE_PROJECT_USERNAME", "CIRCLE_PROJECT_REPONAME", "CIRCLE_BUILD_NUM"].all? { |x| env[x] && !env[x].empty? }

      # Uses the Circle API to determine if it's a PR otherwise
      api = CircleAPI.new(env["CIRCLE_CI_API_TOKEN"])
      api.pull_request?(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      # CircleCI doesn't provide a repo url env variable :/
      self.repo_url = GitRepo.new.origins

      pr_url = env["CI_PULL_REQUEST"]

      # If it's not a real URL, use the Circle API
      unless pr_url && URI.parse(pr_url).kind_of?(URI::HTTP)
        api = CircleAPI.new(env["CIRCLE_CI_API_TOKEN"])
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
                  "PR path: #{pr_path}" \
                  "Keys: #{env.keys}"
        raise message.red
      end
    end
  end
end
