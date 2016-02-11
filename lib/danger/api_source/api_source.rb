module Danger
  module APISource
    # "abstract" API class
    class API
      attr_accessor :ci_source, :pr_json, :issue_json, :environment, :base_commit, :head_commit
      def initialize(ci_source, environment = nil)
          self.ci_source = ci_source
          self.environment = environment
      end
       
      def self.validates?(_env)
        false
      end
    def client
      puts "INITIALIZE client"
    end

    def fetch_details
      puts "fetch details"
    end

    def fetch_issue_details(pr_json)
      puts "fetch issue details"
    end

    def base_commit
      puts "base commit"
    end

    def head_commit
      puts "head_commit"
    end

    def pr_title
      puts "pr_title"
    end

    def pr_body
      puts "pr_body"
    end

    def pr_author
      puts "pr_author"
    end

    def pr_labels
      puts "pr_labels"
    end

    # Sending data to GitHub
    def update_pull_request!(warnings: nil, errors: nil, messages: nil)
      puts "update pull request"
    end
end
  end
end
