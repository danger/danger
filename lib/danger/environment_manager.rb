require "danger/ci_source/travis"
require "danger/ci_source/circle"
require "danger/request_sources/github"

module Danger
  class EnvironmentManager
    attr_accessor :travis, :circle, :github, :git

    def initialize(env)
      self.travis = Travis.new(env) if Travis.validates?(env)
      self.circle = CircleCI.new(env) if CircleCI.validates?(env)
      raise "Could not find a CI source" unless self.travis || self.circle

      self.github = GitHub.new(travis || circle)
    end

    def fill_environment_vars
      github.fetch_details

      self.git = GitRepo.new
    end
  end
end
