require "danger/request_sources/github/github"

module Danger
  # https://groupon.github.io/DotCi

  # ### CI Setup
  # DotCi is a layer on top of jenkins. So, if you're using DotCi, you're hosting your own environment.
  #
  # ### Token Setup
  #
  # #### GitHub
  # As you own the machine, it's up to you to add the environment variable for the `DANGER_GITHUB_API_TOKEN`.
  #
  class DotCi < CI
    def self.validates_as_ci?(env)
      env.key? "DOTCI"
    end

    def self.validates_as_pr?(env)
      !env["DOTCI_PULL_REQUEST"].nil? && !env["DOTCI_PULL_REQUEST"].match(/^[0-9]+$/).nil?
    end

    def supported_request_sources
      @supported_request_sources ||= begin
        [
          Danger::RequestSources::GitHub
        ]
      end
    end

    def initialize(env)
      self.repo_url = self.class.repo_url(env)
      self.pull_request_id = self.class.pull_request_id(env)
      repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/]+)$})
      self.repo_slug = repo_matches[2].gsub(/\.git$/, "") unless repo_matches.nil?
    end

    def self.pull_request_id(env)
      env["DOTCI_PULL_REQUEST"]
    end

    def self.repo_url(env)
      if env["DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL"]
        env["DOTCI_INSTALL_PACKAGES_GIT_CLONE_URL"]
      elsif env["DOTCI_DOCKER_COMPOSE_GIT_CLONE_URL"]
        env["DOTCI_DOCKER_COMPOSE_GIT_CLONE_URL"]
      else
        env["GIT_URL"]
      end
    end
  end
end
