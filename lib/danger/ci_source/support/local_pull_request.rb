module Danger
  class LocalPullRequest
    attr_reader :pull_request_id, :sha

    def initialize(log_line)
      @pull_request_id = log_line.match(/#(?<id>[0-9]+)/)[:id]
      @sha = log_line.split(" ".freeze).first
    end

    def valid?
      pull_request_id && sha
    end
  end
end
