module Danger
  class FindRemoteFromURL
    REGEXP = %r{
      (?<slug>[^/]+/[^/]+)
      (/(pull|merge_requests|pull-requests)/)
      (?<id>\d+)
    }x

    def initialize(url)
      @url = url
    end

    def call
      if matched = url.match(REGEXP)
        PullRequestInfo.new(matched[:slug], matched[:id])
      end
    end

    private

    attr_reader :url
  end

  class PullRequestInfo
    attr_reader :slug, :id

    def initialize(slug, id)
      @slug = slug
      @id = id
    end
  end
end
