require "set"

module Danger
  # ### CI Setup
  #
  # Add a Run Script task that executes `danger` (or `bundle exec danger` if you're using Bundler
  # to manage your gems) as your as part of your Bamboo plan.
  # The minimum supported version is Bamboo 6.9.
  #
  # ### Token Setup
  #
  # IMPORTANT: All required Bamboo environment variables will be available
  # only if the plan is run as part of a pull request. This can be achieved by selecting:
  # Configure plan -> Branches -> Create plan branch: "When pull request is created".
  # Otherwise, `bamboo_repository_pr_key` and `bamboo_planRepository_repositoryUrl`
  # will not be available.
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
      self.repo_url = env["bamboo_planRepository_repositoryUrl"]
      self.pull_request_id = env["bamboo_repository_pr_key"]
      repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/]+?)(\.git$|$)})
      self.repo_slug = repo_matches[2] unless repo_matches.nil?
    end
  end
end
