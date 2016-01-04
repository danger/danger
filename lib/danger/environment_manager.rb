require "danger/ci_source/ci_source"
require "danger/request_sources/github"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :github, :git

    def initialize(env)
      CISource.constants.each do |symb|
        c = CISource.const_get(symb)
        next unless c.kind_of?(Class)

        if c.validates?(env)
          self.ci_source = c.new(env)
          break
        end
      end

      raise "Could not find a CI source".red unless ci_source

      self.github = GitHub.new(ci_source)
    end

    def fill_environment_vars
      github.fetch_details

      self.git = GitRepo.new
    end
  end
end
