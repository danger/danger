require "danger/ci_source/ci_source"
require "danger/request_sources/github"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :request_source, :scm

    def initialize(env)
      CISource.constants.each do |symb|
        c = CISource.const_get(symb)
        next unless c.kind_of?(Class)
        next unless c.validates?(env)

        self.ci_source = c.new(env)
        if self.ci_source.repo_slug and self.ci_source.pull_request_id
          break
        else
          puts "Not a Pull Request - skipping `danger` run"
          self.ci_source = nil
          return nil
        end
      end

      raise "Could not find a CI source".red unless self.ci_source

      # only GitHub for now, open for PRs adding more!
      self.request_source = GitHub.new(self.ci_source, ENV)
    end

    def fill_environment_vars
      request_source.fetch_details

      self.scm = GitRepo.new # For now
    end
  end
end
