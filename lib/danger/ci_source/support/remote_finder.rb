module Danger
  class RemoteFinder
    def initialize(github_host, remote_logs)
      @github_host = github_host
      @remote_logs = remote_logs
    end

    def call
      remote_url_matches && remote_url_matches["repo_slug"]
    end

    private

    attr_reader :remote_logs, :github_host

    # @return [String] The remote URL
    def remote
      @remote ||= remote_logs.lines.grep(/Fetch URL/)[0].split(": ".freeze, 2)[1]
    end

    # @return [nil / MatchData] MatchData object or nil if not matched
    def remote_url_matches
      remote.match(%r{#{Regexp.escape(github_host)}(:|\/|(:\/))(?<repo_slug>[^/]+/.+?)(?:\.git)?$})
    end
  end
end
