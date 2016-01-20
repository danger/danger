# https://circleci.com/docs/environment-variables
require 'uri'

module Danger
  module CISource
    class CircleCI < CI
      def self.validates?(env)
        return !env["CIRCLE_BUILD_NUM"].nil? &&
               !env["CI_PULL_REQUEST"].nil?
      end

      def initialize(env)
        if URI.parse(env["CI_PULL_REQUEST"]).path.split("/").count == 5
          paths = URI.parse(env["CI_PULL_REQUEST"]).path.split("/")
          # The first one is an extra slash, ignore it
          self.repo_slug = paths[1] + "/" + paths[2]
          self.pull_request_id = paths[4]
        end
      end
    end
  end
end
