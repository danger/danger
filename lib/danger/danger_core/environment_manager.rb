require "danger/ci_source/ci_source"
require "danger/request_sources/request_source"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :request_source, :scm

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

      raise_error_for_no_request_source unless self.request_source
      self.scm = self.request_source.scm
    end

    def pr?
      self.ci_source != nil
    end

    def fill_environment_vars
      request_source.fetch_details
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

    def raise_error_for_no_request_source
      title = ""
      subtitle = ""
      repo = ci_source.repo_url
      case repo
      when repo =~ /github/
        title = "For your GitHub repo, you need to expose:" + RequestSources::GitHub.env_vars.join(", ").yellow
      when repo =~ /gitlab/
        title = "For your GitLab repo, you need to expose:" + RequestSources::GitLab.env_vars.join(", ").yellow

      when repo =~ /bitbucket.org/
        title = "For your BitBucket repo, you need to expose:" + RequestSources::BitbucketCloud.env_vars.join(", ").yellow
      else
        available = RequestSources::RequestSource.available_request_sources.map do |klass|
        " - #{klass}, #{klass.env_vars.join(', ').yellow}"
        end
        title = "For Danger to run on this project, you need to expose some of following the ENV vars\n#{available.join('\n')}"
      end

      if ci_source.class == Danger::Travis
        subtitle = "If you have an open source project, you should ensure 'Display value in build log' enabled, so that PRs from forks work."
      end

      repo_url.

      keys = env.keys

      "Could not find an API for "

      # loop through all the API clients
      # indicate their env vars
      # ensure them that we know that you're on travis or whatever
      #
      # raise "Could not find a Request Source for #{ci_klass}\nCI: #{ci_source.inspect}".red
    end
  end
end
