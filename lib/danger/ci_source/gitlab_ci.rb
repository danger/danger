# http://docs.gitlab.com/ce/ci/variables/README.html
require "uri"
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your .gitlab-ci.yml:
  # ```yml
  # before_script:
  #  - bundle install
  # danger:
  #   script:
  #    - bundle exec danger
  # ```
  # ### Token Setup
  #
  # Add the `DANGER_GITLAB_API_TOKEN` to your pipeline env variables if you
  # are hosting your code on GitLab. If you are using GitLab as a mirror
  # for the purpose of CI/CD, while hosting your repo on GitHub, set the
  # `DANGER_GITHUB_API_TOKEN` as well as the project repo URL to
  # `DANGER_PROJECT_REPO_URL`.

  class GitLabCI < CI
    def self.validates_as_ci?(env)
      env.key? "GITLAB_CI"
    end

    def self.validates_as_pr?(env)
      exists = [
        "GITLAB_CI", "CI_PROJECT_PATH"
      ].all? { |x| env[x] }

      exists && determine_pull_or_merge_request_id(env).to_i > 0
    end

    def self.determine_pull_or_merge_request_id(env)
      return env["CI_MERGE_REQUEST_IID"] if env["CI_MERGE_REQUEST_IID"]
      return env["CI_EXTERNAL_PULL_REQUEST_IID"] if env["CI_EXTERNAL_PULL_REQUEST_IID"]
      return 0 unless env["CI_COMMIT_SHA"]

      project_path = env["CI_MERGE_REQUEST_PROJECT_PATH"] || env["CI_PROJECT_PATH"]
      base_commit = env["CI_COMMIT_SHA"]
      client = RequestSources::GitLab.new(nil, env).client

      if (Gem::Version.new(client.version.version) >= Gem::Version.new("10.7"))
        #Use the 'list merge requests associated with a commit' API, for speeed
        # (GET /projects/:id/repository/commits/:sha/merge_requests) available for GitLab >= 10.7
        merge_request = client.commit_merge_requests(project_path, base_commit, state: :opened).first
      else
        merge_requests = client.merge_requests(project_path, state: :opened)
        merge_request = merge_requests.auto_paginate.find do |mr|
          mr.sha == base_commit
        end
      end
      merge_request.nil? ? 0 : merge_request.iid
    end

    def initialize(env)
      @env = env
      @repo_slug = slug_from(env)
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab
      ]
    end

    def pull_request_id
      @pull_request_id ||= self.class.determine_pull_or_merge_request_id(@env)
    end

    private

    def slug_from(env)
      if env["DANGER_PROJECT_REPO_URL"]
        env["DANGER_PROJECT_REPO_URL"].split('/').last(2).join('/')
      else
        env["CI_MERGE_REQUEST_PROJECT_PATH"] || env["CI_PROJECT_PATH"]
      end
    end
  end
end
