# https://circleci.com/docs/environment-variables
require 'uri'
require 'gitlab'

module Danger
  module APISource
    class GitlabCI < API
      def self.validates?(env)
        return !env["GITLAB_CI"].nil? && !env["GITLAB_CI_PULL"].nil?
      end
      def fetch_details
        # FIXME project ID + PR ID (use repo_slug and pr_id)
        self.pr_json = client.merge_request(107, 226)
        #fetch_issue_details(self.pr_json)
      end
      def client 
        # FIXME dynamic tokens via ENV
        @client ||= Gitlab.client(endpoint: 'http://gitlab.krone.at/api/v3', private_token: 'Wypos9xJ3LdHXpzQQskq')
      end
      def base_commit
        self.pr_json.target_branch
      end
      def head_commit
        self.pr_json.source_branch
      end
      def pr_author
        self.pr_json.author.username
      end
      def pr_body
        self.pr_json.description
      end
      def pr_title
        self.pr_json.title
      end

      def update_pull_request!(warnings: nil, errors: nil, messages: nil)
        puts "update pull request"
        puts "##################"
        puts warnings.inspect
        puts errors.inspect
        puts messages.inspect
      end
      def self.initialize(cisource, env = nil) 
          # The first one is an extra slash, ignore it
          #self.repo_slug = "FXF/FXF-IOS"
          #self.pull_request_id = env["GITLAB_CI_PULL"];
      end
    end
  end
end
