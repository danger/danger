# https://docs.codemagic.io/building/environment-variables/

module Danger
  # ### CI Setup
  #
  # Add a script step to your workflow:
  #
  # ```
  # - name: Running Danger
  #   script: |
  #     bundle install
  #     bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # Add the following environment variables to your workflow's environment configuration.
  # https://docs.codemagic.io/getting-started/yaml/
  #
  # #### GitHub
  # Add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV.
  #
  # #### GitLab
  # Add the `DANGER_GITLAB_API_TOKEN` to your build user's ENV.
  #
  # #### Bitbucket Cloud
  # Add the `DANGER_BITBUCKETSERVER_USERNAME`, `DANGER_BITBUCKETSERVER_PASSWORD`
  # to your build user's ENV.
  #
  # #### Bitbucket server
  # Add the `DANGER_BITBUCKETSERVER_USERNAME`, `DANGER_BITBUCKETSERVER_PASSWORD`
  # and `DANGER_BITBUCKETSERVER_HOST` to your build user's ENV.
  #
  class Codemagic < CI
    def self.validates_as_ci?(env)
      env.key? "FCI_PROJECT_ID"
    end

    def self.validates_as_pr?(env)
      return !env["FCI_PULL_REQUEST_NUMBER"].to_s.empty?
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
      self.pull_request_id = env["FCI_PULL_REQUEST_NUMBER"]
      self.repo_slug = env["FCI_REPO_SLUG"]
      self.repo_url = GitRepo.new.origins # Codemagic doesn't provide a repo url env variable for n
    end
  end
end
