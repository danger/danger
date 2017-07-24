module Danger
  # ### CI Setup
  #
  # Read how you can setup Danger on the buddybuild blog:
  # https://www.buddybuild.com/blog/using-danger-with-buddybuild/
  #
  # ### Token Setup
  #
  # Login to buddybuild and select your app. Go to your *App Settings* and
  # in the *Build Settings* menu on the left, choose *Environment Variables*.
  # http://docs.buddybuild.com/docs/environment-variables
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
  # ### Running Danger
  #
  # Once the environment variables are all available, create a custom build step
  # to run Danger as part of your build process:
  # http://docs.buddybuild.com/docs/custom-prebuild-and-postbuild-steps
  class Buddybuild < CI
    #######################################################################
    def self.validates_as_ci?(env)
      value = env["BUDDYBUILD_BUILD_ID"]
      return !value.nil? && !env["BUDDYBUILD_BUILD_ID"].empty?
    end

    #######################################################################
    def self.validates_as_pr?(env)
      value = env["BUDDYBUILD_PULL_REQUEST"]
      return !value.nil? && !env["BUDDYBUILD_PULL_REQUEST"].empty?
    end

    #######################################################################
    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud
      ]
    end

    #######################################################################
    def initialize(env)
      self.repo_slug = env["BUDDYBUILD_REPO_SLUG"]
      self.pull_request_id = env["BUDDYBUILD_PULL_REQUEST"]
      self.repo_url = GitRepo.new.origins # Buddybuild doesn't provide a repo url env variable for now
    end
  end
end
