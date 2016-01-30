# For more info see: https://github.com/schacon/ruby-git

require 'git'
require 'uri'

module Danger
  module CISource
    class LocalGitRepo < CI

      # Never validate, it's not useful in production
      def self.validates?(env)
        false
      end

      def initialize(env)

        git = Git.open(".")
        if git.remote("origin")
          url = git.remote("origin").url
          # deal with https://
          if url.starts_with "https://github.com/"
            self.repo_slug = url.replace("https://github.com/", "").replace(".git", '')

          # deal with SSH origin
          elsif url.starts_with "git@github.com:"
            self.repo_slug = url.replace("git@github.com:", "").replace(".git", '')
          end
        end

        logs = git.log.since('2 weeks ago')
        # Look for something like
        # "Merge pull request #38 from KrauseFx/funky_circles\n\nAdd support for GitHub compare URLs that don't conform
        pr_merge = logs.detect { |log| (/Merge pull request #[0-9]* from/ =~ log.message) == 0 }
        if pr_merge
          # then pull out the 38, to_i
          self.pull_request_id = pr_merge.replace("Merge pull request #", "").to_i
          self.base_commit = pr_merge.parents.[0].sha
          self.head_commit = pr_merge.parents.[1].sha
        end
      end
    end
  end
end
