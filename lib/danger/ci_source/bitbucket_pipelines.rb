module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your `bitbucket-pipelines.yml`.
  # ```yaml
  #   script:
  #     - bundle exec danger --verbose
  # ```
  #
  # ### Token Setup
  #
  # Add `DANGER_BITBUCKETCLOUD_USERNAME` and `DANGER_BITBUCKETCLOUD_PASSWORD` to your pipeline repository variable
  # or instead using `DANGER_BITBUCKETCLOUD_OAUTH_KEY` and `DANGER_BITBUCKETCLOUD_OAUTH_SECRET`.
  #
  # You can find them in Settings > Pipelines > Repository Variables

  class BitbucketPipelines < CI

    def self.validates_as_ci?(env)
      env.key? "BITBUCKET_BUILD_NUMBER"
    end

    def self.validates_as_pr?(env)
      env.key? "BITBUCKET_PR_ID"
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::BitbucketCloud]
    end

    def initialize(env)
      self.repo_url = env["BITBUCKET_GIT_HTTP_ORIGIN"]
      self.repo_slug = "#{env["BITBUCKET_REPO_OWNER"]}/#{env["BITBUCKET_REPO_SLUG"]}"
      self.pull_request_id = env["BITBUCKET_PR_ID"]
    end
  end
end
