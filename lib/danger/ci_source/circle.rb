# https://circleci.com/docs/environment-variables
require 'uri'
require 'danger/ci_source/circle_api'

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
      env.key? 'CIRCLE_BUILD_NUM'
    end

    def self.validates_as_pr?(env)
      return true if env['CI_PULL_REQUEST']

      # Uses the Circle API to determine if it's a PR otherwose
      @circle_token = env['CIRCLE_CI_API_TOKEN']
      !pull_request_url(env).nil?
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def client
      @client ||= CircleAPI.new(@circle_token)
    end

    def fetch_pull_request_url(repo_slug, build_number)
      build_json = client.fetch_build(repo_slug, build_number)
      build_json[:pull_request_urls].first
    end

    def pull_request_url(env)
      url = env['CI_PULL_REQUEST']

      if url.nil? && !env['CIRCLE_PROJECT_USERNAME'].nil? && !env['CIRCLE_PROJECT_REPONAME'].nil?
        repo_slug = env['CIRCLE_PROJECT_USERNAME'] + '/' + env['CIRCLE_PROJECT_REPONAME']
        url = fetch_pull_request_url(repo_slug, env['CIRCLE_BUILD_NUM'])
      end

      url
    end

    def initialize(env)
      self.repo_url = GitRepo.new.origins # CircleCI doesn't provide a repo url env variable :/

      @circle_token = env['CIRCLE_CI_API_TOKEN']
      url = pull_request_url(env)

      if URI.parse(url).path.split('/').count == 5
        paths = URI.parse(url).path.split('/')
        # The first one is an extra slash, ignore it
        self.repo_slug = paths[1] + '/' + paths[2]
        self.pull_request_id = paths[4]
      end
    end
  end
end
