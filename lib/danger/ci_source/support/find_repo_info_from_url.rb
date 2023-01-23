require "danger/ci_source/support/repo_info"

module Danger
  class FindRepoInfoFromURL
    REGEXP = %r{
      ://[^/]+/
      (([^/]+/){1,2}_git/)?
      (?<slug>[^/]+(/[^/]+){0,2})
      (/(pull|pullrequest|merge_requests|pull-requests)/)
      (?<id>\d+)
    }x.freeze

    # Regex used to extract info from Bitbucket server URLs, as they use a quite different format
    REGEXPBB = %r{
      (?:[/:])projects
      /([^/.]+)
      /repos/([^/.]+)
      /pull-requests
      /(\d+)
    }x.freeze

    def initialize(url)
      @url = url
    end

    def call
      matched = url.match(REGEXPBB)

      if matched
        RepoInfo.new("#{matched[1]}/#{matched[2]}", matched[3])
      else
        matched = url.match(REGEXP)
        if matched
          RepoInfo.new(matched[:slug], matched[:id])
        end
      end
    end

    private

    attr_reader :url
  end
end
