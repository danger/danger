module Danger
  class RemotePullRequest
    attr_reader :pull_request_id, :sha, :head, :base

    def initialize(pull_request_id, head, base)
      @pull_request_id = pull_request_id
      @head = head
      @base = base
    end

    def valid?
      pull_request_id && head && base
    end
  end
end
