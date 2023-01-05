module Danger
  # ### CI Setup
  #
  # In order to work with Xcode Cloud and Danger, you will need to add `bundle exec danger` to
  # the `ci_scripts/ci_post_xcodebuild.sh` (Xcode Cloud's expected filename for a post-action build script).
  # More details and documentation on Xcode Cloud configuration can be found [here](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts).
  #
  # ### Token Setup
  #
  # You will need to add the `DANGER_GITHUB_API_TOKEN` to your build environment.
  # If running on GitHub Enterprise, make sure you also set the expected values for
  # both `DANGER_GITHUB_API_HOST` and `DANGER_GITHUB_HOST`.
  #
  class XcodeCloud < CI
    def self.validates_as_ci?(env)
      env.key? "CI_XCODEBUILD_ACTION"
    end

    def self.validates_as_pr?(env)
      env.key? "CI_PULL_REQUEST_NUMBER"
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::GitLab,
        Danger::RequestSources::BitbucketCloud,
        Danger::RequestSources::BitbucketServer
      ]
    end

    def initialize(env)
      self.repo_slug = env["CI_PULL_REQUEST_SOURCE_REPO"]
      self.pull_request_id = env["CI_PULL_REQUEST_NUMBER"]
      self.repo_url = env["CI_PULL_REQUEST_HTML_URL"]
    end
  end
end
