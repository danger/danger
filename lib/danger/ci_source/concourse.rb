require "git"
require "danger/request_sources/local_only"

module Danger
# Concourse CI Integration
#
# https://concourse-ci.org/
#
  # ### CI Setup
  #
  # With Concourse, you run the docker images yourself, so you will want to add `yarn danger ci` within one of your build jobs.
  #
  #   ```shell
  #    build:
  #      image: golang
  #        commands:
  #          - ...
  #          - yarn danger ci
  #   ```
  #
  # ### Environment Variable Setup
  #
  # As this is self-hosted, you will need to add the `CONCOURSE` environment variable `export CONCOURSE=true` to your build environment,
  # as well as setting environment variables for `PULL_REQUEST_ID` and `REPO_SLUG`. Assuming you are using the github pull request resource
  # https://github.com/jtarchie/github-pullrequest-resource the id of the PR can be accessed from `git config --get pullrequest.id`.
  #
  # ### Token Setup
  #
  # Once again as this is self-hosted, you will need to add `DANGER_GITHUB_API_TOKEN` environment variable to the build environment.
  # The suggested method of storing the token is within the vault - https://concourse-ci.org/creds.html

  class Concourse < CI
    def self.validates_as_ci?(env)
      env.key? "CONCOURSE"
    end

    def self.validates_as_pr?(env)
      exists = ["PULL_REQUEST_ID", "REPO_SLUG"].all? { |x| env[x] && !env[x].empty? }
      exists && env["PULL_REQUEST_ID"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud
      ]
    end

    def initialize(env)
      self.repo_slug = env["REPO_SLUG"]

      if env["PULL_REQUEST_ID"].to_i > 0
        self.pull_request_id = env["PULL_REQUEST_ID"]
      end
      self.repo_url = GitRepo.new.origins
    end

  end
end
