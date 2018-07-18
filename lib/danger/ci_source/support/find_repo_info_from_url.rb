require "danger/ci_source/support/repo_info"

module Danger
  class FindRepoInfoFromURL
    REGEXP = %r{
      ://[^/]+/
      (?<slug>[^/]+(/[^/]+){1,2})
      (/(pull|merge_requests|pull-requests)/)
      (?<id>\d+)
    }x

    def initialize(url)
      @url = url
    end

    def call
      matched = url.match(REGEXP)

      if matched
        RepoInfo.new(matched[:slug], matched[:id])
      end
    end

    private

    attr_reader :url
  end
end
