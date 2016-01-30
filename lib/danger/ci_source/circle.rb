# https://circleci.com/docs/environment-variables
require 'uri'

module Danger
  module CISource
    class CircleCI < CI
      def self.validates?(env)
        return !env["CIRCLE_BUILD_NUM"].nil? && !env["CI_PULL_REQUEST"].nil?
      end

      def initialize(env)
        if URI.parse(env["CI_PULL_REQUEST"]).path.split("/").count == 5
          paths = URI.parse(env["CI_PULL_REQUEST"]).path.split("/")
          # The first one is an extra slash, ignore it
          self.repo_slug = paths[1] + "/" + paths[2]
          self.pull_request_id = paths[4]
        end

        # The url we get from Circle can include "^" which isn't allowed in
        # ruby's URI, so we decode to a URL then unencode at the end.

        if env["CIRCLE_COMPARE_URL"]
          compare_encoded = URI.escape(env["CIRCLE_COMPARE_URL"])
          url =  URI.parse(compare_encoded)

          return unless url.path.split("/").count == 5

          commit_ref = URI.unescape(url.path.split("/").last)

          self.head_commit = commit_ref.split("...").last
          self.base_commit = commit_ref.split("...").first
        end
      end
    end
  end
end
