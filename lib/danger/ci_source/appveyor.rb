# https://www.appveyor.com/docs/build-configuration/
module Danger
  # ### CI Setup
  #
  # Install dependencies and add a danger step to your `appveyor.yml`.
  # ```yaml
  # install:
  # - cmd: >-
  #     set PATH=C:\Ruby25-x64\bin;%PATH%
  #
  #     bundle install
  # after_test:
  # - cmd: >-
  #     bundle exec danger
  # ```
  #
  # ### Token Setup
  #
  # For public repositories, add your plain token to environment variables in `appveyor.yml`.
  # Encrypted environment variables will not be decrypted on PR builds.
  # see here: https://www.appveyor.com/docs/build-configuration/#secure-variables
  # ```yaml
  # environment:
  #   DANGER_GITHUB_API_TOKEN: <YOUR_TOKEN_HERE>
  # ```
  #
  # For private repositories, enter your token in `Settings>Environment>Environment variables>Add variable` and turn on `variable encryption`.
  # You will see encrypted variable text in `Settings>Export YAML` so just copy to your `appveyor.yml`.
  # ```yaml
  # environment:
  #   DANGER_GITHUB_API_TOKEN:
  #     secure: <YOUR_ENCRYPTED_TOKEN_HERE>
  # ```
  #
  class AppVeyor < CI
    def self.validates_as_ci?(env)
      env.key? "APPVEYOR"
    end

    def self.validates_as_pr?(env)
      return false unless env.key? "APPVEYOR_PULL_REQUEST_NUMBER"
      env["APPVEYOR_PULL_REQUEST_NUMBER"].to_i > 0
    end

    def initialize(env)
      self.repo_slug = env["APPVEYOR_REPO_NAME"]
      self.pull_request_id = env["APPVEYOR_PULL_REQUEST_NUMBER"]
      self.repo_url = GitRepo.new.origins # AppVeyor doesn't provide a repo url env variable for now
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::BitbucketCloud,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::GitLab
      ]
    end
  end
end
