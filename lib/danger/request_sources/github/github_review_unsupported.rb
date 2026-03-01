# coding: utf-8

module Danger
  module RequestSources
    module GitHubSource
      class ReviewUnsupported
        attr_reader :id, :body, :status, :review_json

        def initialize; end

        def start; end

        def submit; end

        def message(message, sticky = true, file = nil, line = nil); end

        def warn(message, sticky = true, file = nil, line = nil); end

        def fail(message, sticky = true, file = nil, line = nil); end

        def markdown(message, file = nil, line = nil); end
      end
    end
  end
end
