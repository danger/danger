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

    def ensure_danger_branches_are_setup
      # As this currently just works with GitHub, we can use a github specific feature here:
      pull_id = ci_source.pull_request_id
      test_branch = request_source.base_commit

      # Next, we want to ensure that we have a version of the current branch that at a know location
      scm.exec "branch #{danger_base_branch} #{test_branch}"

      # OK, so we want to ensure that we have a known head branch, this will always represent
      # the head ( e.g. the most recent commit that will be merged. )
      scm.exec "fetch origin +refs/pull/#{pull_id}/merge:#{danger_head_branch}"
    end

    def clean_up
      [danger_base_branch, danger_base_branch].each do |branch|
        scm.exec "branch -d #{branch}"
      end
    end

    def meta_info_for_base
      scm.exec("--no-pager log #{danger_base_branch} -n1")
    end

    def meta_info_for_head
      scm.exec("--no-pager log #{danger_head_branch} -n1")
    end

    def danger_head_branch
      "danger_head"
    end

    def danger_base_branch
      "danger_base"
    end
  end
end
