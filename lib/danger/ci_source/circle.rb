# https://circleci.com/docs/environment-variables
require 'uri'

module Danger
  class CircleCI

    attr_accessor :repo_slug, :pull_request_id

    def self.validates?(env)
      return env["CIRCLE"] != nil && ["CI_PULL_REQUEST"] != nil
    end

    def initialize(env)
      paths = URI::parse(env["CI_PULL_REQUEST"]).path.split("/")
      # the first one is an extra slash, ignore it
      self.repo_slug = paths[1] + "/" + paths[2]
      self.pull_request_id = paths[4]
    end

  end
end
