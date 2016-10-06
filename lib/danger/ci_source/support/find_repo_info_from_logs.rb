require "danger/ci_source/support/repo_info"

module Danger
  class FindRepoInfoFromLogs
    def initialize(github_host, remote_logs)
      @github_host = github_host
      @remote_logs = remote_logs
    end

    def call
      matched = remote.match(regexp)

      if matched
        RepoInfo.new(matched["repo_slug"], nil)
      end
    end

    private

    attr_reader :remote_logs, :github_host

    def remote
      remote_logs.lines.grep(/Fetch URL/)[0].split(": ".freeze, 2)[1]
    end

    def regexp
      %r{
        #{Regexp.escape(github_host)}
        (:|/|(:/))
        (?<repo_slug>[^/]+/.+?)
        (?:\.git)?$
      }x
    end
  end
end
