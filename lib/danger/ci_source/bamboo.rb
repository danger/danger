require "set"

module Danger
  # ### CI Setup
  #
  # Add `bundle exec danger` as Run Script step inside your plan. XXX expand me.
  #
  # ### Token Setup
  #
  # Bamboo will make available all required environment variables only if the plan is ran as part of
  # a pull request. Otherwise, `bamboo_repository_pr_key` and `bamboo_planRepository_repositoryUrl`
  # variables will not be available.
  #
  # #### Bitbucket Server integration
  # Make sure `DANGER_BITBUCKETSERVER_USERNAME`, `DANGER_BITBUCKETSERVER_PASSWORD`
  # and `DANGER_BITBUCKETSERVER_HOST` ENV variables are all available by XXX.
  #
  class Bamboo < CI
    def supported_request_sources
      @supported_request_sources ||= [
        Danger::RequestSources::BitbucketServer
      ]
    end

    def self.validates_as_ci?(env)
      env.key? "bamboo_buildKey"
    end

    def self.validates_as_pr?(env)
      exists = ["bamboo_repository_pr_key", "bamboo_planRepository_repositoryUrl"].all? { |x| env[x] && !env[x].empty? }
      exists && env["bamboo_repository_pr_key"].to_i > 0
    end

    def initialize(env)
      # TODO: What if there's more than one?
      self.repo_url = env["bamboo_planRepository_repositoryUrl"]
      self.pull_request_id = env["bamboo_repository_pr_key"]
      repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/]+?)(\.git$|$)})
      self.repo_slug = repo_matches[2] unless repo_matches.nil?
    end
  end
end
