module Danger
  class Result
    attr_reader :pull_request_id, :sha, :head, :base

    def initialize(log_line, pull_request_id = nil, head = nil, base = nil)
      @log_line = log_line

      if log_line
        @pull_request_id = log_line.match(/#(?<id>[0-9]+)/)[:id]
        @sha = log_line.split(" ".freeze).first
      else
        @pull_request_id = pull_request_id
        @head = head
        @base = base
      end
    end

    def valid?
      !!(
        (pull_request_id && sha) ||
        (pull_request_id && head && base)
      )
    end

    private

    attr_reader :log_line
  end
end
