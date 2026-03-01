# Following the advice from @czechboy0 https://github.com/danger/danger/issues/171
# https://github.com/czechboy0/Buildasaur
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  #
  # If you're bold enough to use Xcode Bots. You will need to use [Buildasaur](https://github.com/czechboy0/Buildasaur)
  # in order to work with Danger. This will set up your build environment for you, as the name of the bot contains all
  # of the environment variables that Danger needs to work.
  #
  # With Buildasaur set up, you can edit your job to add `bundle exec danger` as a post-action build script.
  #
  # ### Token Setup
  #
  # As this is self-hosted, you will need to add the `DANGER_GITHUB_API_TOKEN` to your build user's ENV. The alternative
  # is to pass in the token as a prefix to the command `DANGER_GITHUB_API_TOKEN="123" bundle exec danger`.`.
  #
  class XcodeServer < CI
    def self.validates_as_ci?(env)
      env.key? "XCS_BOT_NAME"
    end

    def self.validates_as_pr?(env)
      value = env["XCS_BOT_NAME"]
      !value.nil? && value.include?("BuildaBot")
    end

    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::GitHub,
        Danger::RequestSources::BitbucketServer,
        Danger::RequestSources::BitbucketCloud
      ]
    end

    def initialize(env)
      bot_name = env["XCS_BOT_NAME"]
      return if bot_name.nil?

      repo_matches = bot_name.match(/\[(.+)\]/)
      self.repo_slug = repo_matches[1] unless repo_matches.nil?
      pull_request_id_matches = bot_name.match(/#(\d+)/)
      self.pull_request_id = pull_request_id_matches[1] unless pull_request_id_matches.nil?
      self.repo_url = GitRepo.new.origins # Xcode Server doesn't provide a repo url env variable :/
    end
  end
end
