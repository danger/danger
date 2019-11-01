require "set"

module Danger
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
      env.key? "bamboo_repository_pr_key"
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
