# For more info see: https://github.com/schacon/ruby-git

require 'git'
require 'uri'

module Danger
  module CISource
    class LocalGitRepo < CI
      def self.validates?(env)
        return !env["DANGER_USE_LOCAL_GIT"].nil?
      end

      def initialize(*)
        git = Git.open(".")
        if git.remote("origin")
          url = git.remote("origin").url
          # deal with https://
          if url.start_with? "https://github.com/"
            self.repo_slug = url.gsub("https://github.com/", "").gsub(".git", '')

          # deal with SSH origin
          elsif url.start_with? "git@github.com:"
            self.repo_slug = url.gsub("git@github.com:", "").gsub(".git", '')
          end
        end

        logs = git.log.since('2 weeks ago')
        # Look for something like
        # "Merge pull request #38 from KrauseFx/funky_circles\n\nAdd support for GitHub compare URLs that don't conform
        pr_merge = logs.detect { |log| (/Merge pull request #[0-9]* from/ =~ log.message) == 0 }
        if pr_merge
          # then pull out the 38, to_i
          self.pull_request_id = pr_merge.name.gsub("Merge pull request #", "").to_i
          self.base_commit = pr_merge.parents[0].sha
          self.head_commit = pr_merge.parents[1].sha
        end
      end
    end
  end
end
