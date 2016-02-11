# https://circleci.com/docs/environment-variables
require 'uri'
require 'gitlab'

module Danger
  module APISource
    class GitlabAPI < API
      def self.validates?(env)
        return !env["GITLAB_PROJECT_ID"].nil? && !env["GITLAB_MR_ID"].nil?
      end
      def fetch_details
        puts client.inspect
       self.pr_json = client.merge_request(self.ci_source.repo_slug, self.ci_source.pull_request_id)
       #self.pr_json = client.merge_request(107, 226)
      end
      def client 
        token = @environment["DANGER_GITLAB_PRIVATE_TOKEN"]
        endpoint = @environment["DANGER_GITLAB_ENDPOINT"]
        raise "No API given, please provide one using `DANGER_GITLAB_PRIVATE_TOKEN` and `DANGER_GITLAB_ENDPOINT`" unless (token && endpoint)
        @client ||= Gitlab.client(endpoint: endpoint, private_token: token)
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

      def generate_comment(warnings: [], errors: [], messages: [], empty: false)
      require 'erb'

      md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/github.md.erb")

      # erb: http://www.rrn.dk/rubys-erb-templating-system
      # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
      @tables = [
        { name: "Error", emoji: "no_entry_sign", content: errors },
        { name: "Warning", emoji: "warning", content: warnings },
        { name: "Message", emoji: "book", content: messages }
      ]
      @tables_empty = [
            { name: "All Good", emoji: "ship", content: ["Danger has not found anymore issues"]}
      ]
      if empty 
        @tables = @tables_empty  
      end
      return ERB.new(File.read(md_template), 0, "-").result(binding)
      
    end
      def update_pull_request!(warnings: nil, errors: nil, messages: nil)

        
        comments = client.merge_request_comments(107,226)
        already_reported = comments.reject { |issue| issue.body.include?("generated_by_danger") == false }

        if (warnings + errors + messages).empty?
          #as we cannot delete MR comments via api - we update it to a "all good state"
          body = generate_comment(warnings: warnings, errors: errors, messages: messages, empty: true)
          already_reported.each do | danger_comment |
                client.edit_merge_request_comment(107,226, danger_comment.id, body)
          end
        else
          body = generate_comment(warnings: warnings, errors: errors, messages: messages)
          if already_reported.length == 0
              client.create_merge_request_comment(107,226, body);      
          else 
            already_reported.each do | danger_comment |
                client.edit_merge_request_comment(107,226, danger_comment.id, body)
            end
          end

          #client.create_merge_request_comment(107,226, body);
        end

      end
      def self.initialize(cisource, env = nil) 
          # The first one is an extra slash, ignore it
          #self.repo_slug = "FXF/FXF-IOS"
          #self.pull_request_id = env["GITLAB_CI_PULL"];
         
      end
    end
  end
end
