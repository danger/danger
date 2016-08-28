# http://docs.gitlab.com/ce/ci/variables/README.html
require "uri"

module Danger
  # ### CI Setup
  # GitLab CI is currently not supported because GitLab's runners don't expose
  # the required values in the environment. Namely CI_MERGE_REQUEST_ID does not
  # exist as of yet, however there is an
  # [MR](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5698) fixing this.
  # If that has been merged and you are using either gitlab.com or a release
  # with that change this CISource will work.
  #
  class GitLabCI < CI
    def self.validates_as_ci?(env)
      env.key? "GITLAB_CI"
    end

    def self.validates_as_pr?(env)
      exists = ["CI_MERGE_REQUEST_ID", "CI_PROJECT_ID", "GITLAB_CI"].all? { |x| env[x] }
      exists && env["CI_MERGE_REQUEST_ID"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitLab]
    end

    def initialize(env)
      self.repo_slug = env["CI_PROJECT_ID"]
      self.pull_request_id = env["CI_MERGE_REQUEST_ID"]
    end
  end
end
