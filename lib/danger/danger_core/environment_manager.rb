require "danger/ci_source/ci_source"
require "danger/danger_core/plugin_host"
require "danger/request_source/request_source"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :request_source, :scm, :plugin_host

    # Finds a Danger::CI class based on the ENV
    def self.local_ci_source(env)
      CI.available_ci_sources.find { |ci| ci.validates_as_ci? env }
    end

    # Uses the current Danger::CI subclass, and sees if it is a PR
    def self.pr?(env)
      local_ci_source(env).validates_as_pr?(env)
    end

    def initialize(env)
      ci_klass = self.class.local_ci_source(env)
      self.ci_source = ci_klass.new(env)

      RequestSources::RequestSource.available_request_sources.each do |klass|
        next unless self.ci_source.supports?(klass)

        request_source = klass.new(self.ci_source, env)
        next unless request_source.validates_as_ci?
        next unless request_source.validates_as_api_source?
        self.request_source = request_source
      end

      raise "Could not find a Request Source for #{ci_klass}".red unless self.request_source
      self.scm = self.request_source.scm

      self.plugin_host = PluginHost.new
    end

    # Are we in a PR where we can do something?
    def pr?
      self.ci_source != nil
    end

    # Others use this to say, OK, everything is ready
    def fill_environment_vars
      request_source.fetch_details
    end

    # The Dangerfile calls this once it's finished its init
    def setup_plugins(dangerfile)
      plugin_host.refresh_plugins(dangerfile)
      dangerfile.extend_with_plugins(plugin_host)
    end

    # Pre-requisites
    def ensure_danger_branches_are_setup
      clean_up

      self.request_source.setup_danger_branches
    end

    # Ensure things that Danger has created are deleted
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
