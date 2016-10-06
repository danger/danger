require "danger/ci_source/support/remote_info"

module Danger
  class FindRemoteFromLogs
    def initialize(github_host, remote_logs)
      @github_host = github_host
      @remote_logs = remote_logs
    end

    def call
      matched = remote.match(%r{#{Regexp.escape(github_host)}(:|/|(:/))(?<repo_slug>[^/]+/.+?)(?:\.git)?$})

      if matched
        RemoteInfo.new(matched["repo_slug"], nil)
      end
    end

    private

    attr_reader :remote_logs, :github_host

    # @return [String] The remote URL
    def remote
      remote_logs.lines.grep(/Fetch URL/)[0].split(": ".freeze, 2)[1]
    end
  end
end
