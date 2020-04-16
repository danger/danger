require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # You can use `danger/danger` Action in your `.github/workflows/xxx.yml`.
  # And so, you can use GITHUB_TOKEN secret as `DANGER_GITHUB_API_TOKEN` environment variable.
  #
  #  ```
  #  ...
  #    steps:
  #      - uses: actions/checkout@v1
  #      - uses: danger/danger@master
  #        env:
  #          DANGER_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  #  ```
  #
  class GitHubActions < CI
    def self.validates_as_ci?(env)
      env.key? "GITHUB_ACTION"
    end

    def self.validates_as_pr?(env)
      env["GITHUB_EVENT_NAME"] == "pull_request"
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["GITHUB_REPOSITORY"]
      pull_request_event = JSON.parse(File.read(env["GITHUB_EVENT_PATH"]))
      self.pull_request_id = pull_request_event['number']
      self.repo_url = pull_request_event['repository']['clone_url']

      # if environment variable DANGER_GITHUB_API_TOKEN is not set, use env GITHUB_TOKEN
      if (env.key? "GITHUB_ACTION") && (!env.key? 'DANGER_GITHUB_API_TOKEN')
        env['DANGER_GITHUB_API_TOKEN'] = env['GITHUB_TOKEN']
      end
    end
  end
end
