# http://docs.gitlab.com/ce/ci/variables/README.html
require "uri"
require "danger/request_sources/gitlab"

module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your .gitlab-ci.yml:
  # ``` yml
  # before_script:
  #  - bundle install
  # danger:
  #   script:
  #    - bundle exec danger
  # ```
  # ### Token Setup
  #
  # Add the `DANGER_GITLAB_API_TOKEN` to your pipeline env variables.
  class GitLabCI < CI
    attr_reader :project_url

    def self.validates_as_ci?(env)
      env.key? "GITLAB_CI"
    end

    def self.validates_as_pr?(env)
      exists = [
        "GITLAB_CI", "CI_PROJECT_PATH"
      ].all? { |x| env[x] }

      exists && determine_merge_request_id(env).to_i > 0
    end

    def self.determine_merge_request_id(env)
      return env["CI_MERGE_REQUEST_ID"] if env["CI_MERGE_REQUEST_ID"]
      return 0 unless env["CI_COMMIT_SHA"]

      project_path = env["CI_PROJECT_PATH"]
      base_commit = env["CI_COMMIT_SHA"]
      client = RequestSources::GitLab.new(nil, env).client

      merge_requests = client.merge_requests(project_path, state: :opened)
      merge_request = merge_requests.auto_paginate.find do |mr|
        mr.sha == base_commit
      end

      merge_request.nil? ? 0 : merge_request.iid
    end

    def initialize(env)
      @env = env
      @repo_slug = env["CI_PROJECT_PATH"]
      @project_url = env["CI_PROJECT_URL"]
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitLab]
    end

    def pull_request_id
      @pull_request_id ||= self.class.determine_merge_request_id(@env)
    end
  end
end
