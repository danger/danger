# https://docs.appcircle.io/environment-variables/managing-variables
# https://docs.appcircle.io/build/build-profile-configuration#environment-variables-configuration
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"
module Danger
  # ### CI Setup
  #
  # Add a Custom Script step to your workflow and set it as a bash:
  #
  # ```shell
  #   cd $AC_REPOSITORY_DIR
  #   bundle install
  #   bundle exec danger
  # ```
  # ### Token Setup
  #
  # Login to Appcircle and select your build profile. Go to your *Config* and
  # choose *Environment Variables*.
  # https://docs.appcircle.io/environment-variables/managing-variables
  #
  # #### GitHub
  # Add the `DANGER_GITHUB_API_TOKEN` to your profile's ENV.
  #
  # #### GitLab
  # Add the `DANGER_GITLAB_API_TOKEN` to your profile's ENV.
  #
  # #### Bitbucket Cloud
  # Add the `DANGER_BITBUCKETSERVER_USERNAME`, `DANGER_BITBUCKETSERVER_PASSWORD`
  # to your profile's ENV.
  #
  # #### Bitbucket server
  # Add the `DANGER_BITBUCKETSERVER_USERNAME`, `DANGER_BITBUCKETSERVER_PASSWORD`
  # and `DANGER_BITBUCKETSERVER_HOST` to your profile's ENV.
  #
  class Appcircle < CI
    def self.validates_as_ci?(env)
      env.key? "AC_APPCIRCLE"
    end

    def self.validates_as_pr?(env)
      return false unless env.key? "AC_PULL_NUMBER"

      env["AC_PULL_NUMBER"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::BitbucketCloud,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::GitLab
      ]
    end

    def initialize(env)
      self.pull_request_id = env["AC_PULL_NUMBER"]
      self.repo_url = env["AC_GIT_URL"]
      self.repo_slug = repo_slug_from(self.repo_url)
    end

    def repo_slug_from(url)
      if url =~ URI::DEFAULT_PARSER.make_regexp
        # Try to parse the URL as a valid URI. This should cover the cases of http/https/ssh URLs.
        begin
          uri = URI.parse(url)
          return uri.path.sub(%r{^(/)}, "").sub(/(.git)$/, "")
        rescue URI::InvalidURIError
          # In case URL could not be parsed fallback to git URL parsing.
          repo_slug_asgiturl(url)
        end
      else
        # In case URL could not be parsed fallback to git URL parsing. git@github.com:organization/repo.git
        repo_slug_asgiturl(url)
      end
    end

    def repo_slug_asgiturl(url)
      matcher_url = url
      repo_matches = matcher_url.match(%r{([/:])(([^/]+/)+[^/]+?)(\.git$|$)})[2]
      return repo_matches unless repo_matches.nil?
    end
  end
end
