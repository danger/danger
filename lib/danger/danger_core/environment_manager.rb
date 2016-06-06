require "danger/ci_source/ci_source"
require "danger/request_source/request_source"

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
          self.ci_source = nil
          return nil
        end
      end

      raise "Could not find a CI source".red unless self.ci_source

      RequestSources::RequestSource.available_request_sources.each do |klass|
        next unless self.ci_source.supports?(klass)

        request_source = klass.new(self.ci_source, ENV)
        next unless request_source.validates?
        self.request_source = request_source
      end

      raise "Could not find a Request Source".red unless self.request_source

      self.scm = self.request_source.scm
    end

    def pr?
      self.ci_source != nil
    end

    def fill_environment_vars
      self.request_source.fetch_details
    end

    def ensure_danger_branches_are_setup
      clean_up

      self.request_source.setup_danger_branches
    end

    def clean_up
      [EnvironmentManager.danger_base_branch, EnvironmentManager.danger_head_branch].each do |branch|
        scm.exec("branch -D #{branch}") unless scm.exec("rev-parse --quiet --verify #{branch}").empty?
      end
    end

    def meta_info_for_base
      scm.exec("--no-pager log #{EnvironmentManager.danger_base_branch} -n1")
    end

    def meta_info_for_head
      scm.exec("--no-pager log #{EnvironmentManager.danger_head_branch} -n1")
    end

    def self.danger_head_branch
      "danger_head"
    end

    def self.danger_base_branch
      "danger_base"
    end
  end
end
