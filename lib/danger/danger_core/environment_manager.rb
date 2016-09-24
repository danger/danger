require "danger/ci_source/ci_source"
require "danger/request_sources/request_source"

module Danger
  class EnvironmentManager
    attr_accessor :ci_source, :request_source, :scm, :ui

    # Finds a Danger::CI class based on the ENV
    def self.local_ci_source(env)
      CI.available_ci_sources.find { |ci| ci.validates_as_ci? env }
    end

    # Uses the current Danger::CI subclass, and sees if it is a PR
    def self.pr?(env)
      local_ci_source(env).validates_as_pr?(env)
    end

    def initialize(env, ui)
      ci_klass = self.class.local_ci_source(env)
      self.ci_source = ci_klass.new(env)
      self.ui = ui

      RequestSources::RequestSource.available_request_sources.each do |klass|
        next unless self.ci_source.supports?(klass)

        request_source = klass.new(self.ci_source, env)
        next unless request_source.validates_as_ci?
        next unless request_source.validates_as_api_source?
        self.request_source = request_source
      end

      raise_error_for_no_request_source(env, ui) unless self.request_source
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

    def raise_error_for_no_request_source(env, ui)
      repo = ci_source.repo_url
      source = nil, title = "", subtitle = ""

      if repo =~ /github/
        source = RequestSources::GitHub
      elsif repo =~ /gitlab/
        source = RequestSources::GitLab
      elsif repo =~ /bitbucket.org/
        source = RequestSources::BitbucketCloud
      else
        source = nil
      end

      if source
        source_name = source.to_s.sub("Danger::RequestSources::", "")
        title = "For your #{source_name} repo, you need to expose: " + source.env_vars.join(", ").yellow
        subtitle = "You may also need: #{source.optional_env_vars.join(', ')}" if source.optional_env_vars.any?
      else
        available = RequestSources::RequestSource.available_request_sources.map do |klass|
          source_name = klass.to_s.sub("Danger::RequestSources::", "")
          " - #{source_name}: #{klass.env_vars.join(', ').yellow}"
        end
        title = "For Danger to run on this project, you need to expose a set of following the ENV vars:\n#{available.join("\n")}"
      end

      if env["TRAVIS_SECURE_ENV_VARS"] == "true"
        subtitle += "\nTravis note: If you have an open source project, you should ensure 'Display value in build log' enabled for these flags, so that PRs from forks work."
        subtitle += "\nThis also means that people can see this token, so this account should have no write access to repos."
      end

      ui.title "Could not set up API to Code Review site for Danger\n"
      ui.puts title
      ui.puts subtitle

      ui.puts "\nFound these keys in your ENV: #{env.keys.join(', ')}."
      ui.puts "\nFailing the build, Danger cannot run without API access."
      ui.puts "You can see more information at http://danger.systems/guides/getting_started.html"
      exit 1
    end
  end
end
