module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your `bitbucket-pipelines.yml`.
  #
  # ```yaml
  #   script:
  #     - bundle exec danger --verbose
  # ```
  #
  # ### Token Setup
  #
  # For username and password, you need to set.
  #
  # - `DANGER_BITBUCKETCLOUD_USERNAME` = The username for the account used to comment, as shown on
  #   https://bitbucket.org/account/
  # - `DANGER_BITBUCKETCLOUD_PASSWORD` = The password for the account used to comment, you could use
  #   [App passwords](https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html#Apppasswords-Aboutapppasswords)
  #   with Read Pull Requests and Read Account Permissions.
  #
  # For OAuth key and OAuth secret, you can get them from.
  #
  # - Open [BitBucket Cloud Website](https://bitbucket.org)
  # - Navigate to Settings > OAuth > Add consumer
  # - Put `https://bitbucket.org/site/oauth2/authorize` for `Callback URL`, and enable Read Pull requests, and Read Account
  #   Permission.
  #
  # - `DANGER_BITBUCKETCLOUD_OAUTH_KEY` = The consumer key for the account used to comment, as show as `Key` on the website.
  # - `DANGER_BITBUCKETCLOUD_OAUTH_SECRET` = The consumer secret for the account used to comment, as show as `Secret` on the
  #   website.
  #
  # For [repository access token](https://support.atlassian.com/bitbucket-cloud/docs/repository-access-tokens/), what you
  # need to create one is:
  #
  # - Open your repository URL
  # - Navigate to Settings > Security > Access Tokens > Create Repository Access Token
  # - Give it a name and set Pull requests write scope

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
      self.repo_slug = "#{env['BITBUCKET_REPO_OWNER']}/#{env['BITBUCKET_REPO_SLUG']}"
      self.pull_request_id = env["BITBUCKET_PR_ID"]
    end
  end
end
