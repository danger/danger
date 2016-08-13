# coding: utf-8
require 'danger/plugin_support/plugin'

module Danger
  class DangerfileBitbucketServerPlugin < Plugin
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::BitbucketServer
      super
    end

    def self.instance_name
      "bitbucket_server"
    end

    def initialize(dangerfile)
      super(dangerfile)
      @bs = dangerfile.env.request_source
    end

    def pr_json
      @bs.pr_json
    end

    def pr_title
      @bs.pr_json[:title].to_s
    end

    def pr_description
      @bs.pr_json[:description].to_s
    end

    def pr_author
      @bs.pr_json[:author][:user][:slug].to_s
    end
  end
end
