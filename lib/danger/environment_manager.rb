require "danger/ci_source/ci"
require "danger/request_sources/github"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :github, :git

    def initialize(env)
      # self.travis = CISource::Travis.new(env) if CISource::Travis.validates?(env)
      # self.circle = CISource::CircleCI.new(env) if CircleCI.validates?(env)
      CISource.constants.each do |symb|
        c = CISource.const_get(symb)
        next unless c.kind_of?(Class)

        puts "ask: #{c}: #{c.validates?(env)}"
        self.ci_source = c.new(env) if c.validates?(env)
      end

      raise "Could not find a CI source" unless ci_source

      self.github = GitHub.new(ci_source)
    end

    def fill_environment_vars
      github.fetch_details

      self.git = GitRepo.new
    end
  end
end
