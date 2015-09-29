require 'rest'
require 'json'

module Danger
  class GitHub

    attr_accessor :ci_source, :pr_json

    def initialize(ci_source)
      self.ci_source = ci_source
    end

    def api_url
      "https://api.github.com/repos/#{ci_source.repo_slug}/pulls/#{ci_source.pull_request_id}"
    end

    def get_details
      response = REST.get api_url
      if response.ok?
        self.pr_json = JSON.parse(response.body)
      else
        puts "Something went wrong getting GitHub details for #{api_url} - (#{response.status_code})"
        puts response.body
        raise "Could not get the pull request details from GitHub."
      end
    end

    def latest_pr_commit_ref
      self.pr_json
    end

  end
end
