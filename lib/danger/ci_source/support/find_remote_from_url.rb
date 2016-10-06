require "danger/ci_source/support/remote_info"

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
      matched = url.match(REGEXP)

      if matched
        RemoteInfo.new(matched[:slug], matched[:id])
      end
    end

    private

    attr_reader :url
  end
end
