# For more info see: https://github.com/schacon/ruby-git

require 'grit'
require 'uri'

module Danger
  module CISource
    class LocalGitRepo < CI
      attr_accessor :base_commit, :head_commit

      def self.validates?(env)
        return !env["DANGER_USE_LOCAL_GIT"].nil?
      end

      def initialize(*)
        git = Grit::Git.new(".")
        # get the remote URL
        remote = git.sh "/usr/local/bin/git remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-"
        if remote
          url = remote[0].strip
          # deal with https://
          if url.start_with? "https://github.com/"
            self.repo_slug = url.gsub("https://github.com/", "").gsub(".git", '')

          # deal with SSH origin
          elsif url.start_with? "git@github.com:"
            self.repo_slug = url.gsub("git@github.com:", "").gsub(".git", '')
          else
            puts "Danger local requires a repository hosted on github."
          end
        end

        # get the most recent PR merge
        logs = git.sh "/usr/local/bin/git log --since='2 weeks ago' --merges --oneline | grep \"Merge pull request\" | head -n 1"
        pr_merge = logs[0].strip
        if pr_merge
          self.pull_request_id = pr_merge.match("#[0-9]*")[0].gsub("#","")
          sha = pr_merge.split(" ")[0]
          parents = git.sh "/usr/local/bin/git rev-list --parents -n 1 #{sha}"
          self.base_commit = parents[0].strip.split(" ")[0]
          self.head_commit = parents[0].strip.split(" ")[1]
        end
        # # Look for something like
        # # "Merge pull request #38 from KrauseFx/funky_circles\n\nAdd support for GitHub compare URLs that don't conform
        # pr_merge = logs.detect { |log| (/Merge pull request #[0-9]* from/ =~ log.message) == 0 }
        # if pr_merge
        #   # then pull out the 38, to_i
        #   self.pull_request_id = pr_merge.message.gsub("Merge pull request #", "").to_i
        #   self.base_commit = pr_merge.parents[0].sha
        #   self.head_commit = pr_merge.parents[1].sha
        # end
      end
    end
  end
end
