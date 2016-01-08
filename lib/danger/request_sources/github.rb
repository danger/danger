require 'rest'
require 'json'
require 'base64'
require 'octokit'

module Danger
  class GitHub
    attr_accessor :ci_source, :pr_json

    def initialize(ci_source)
      self.ci_source = ci_source
    end

    def client
      token = ENV["DANGER_GITHUB_API_TOKEN"]
      raise "No API given, please provide one using `DANGER_GITHUB_API_TOKEN`" unless token

      @client ||= Octokit::Client.new(
        access_token: token
      )
    end

    def fetch_details
      self.pr_json = client.pull_request(ci_source.repo_slug, ci_source.pull_request_id)
    end

    def latest_pr_commit_ref
      self.pr_json[:head][:sha]
    end

    def pr_title
      self.pr_json[:title]
    end

    def pr_body
      self.pr_json[:body]
    end

    def pr_author
      self.pr_json[:user][:login]
    end

    # Sending data to GitHub
    def update_pull_request!(warnings: nil, errors: nil, messages: nil)
      # First, add a comment
      if (warnings + errors + messages).count == 0
        body = generate_comment(warnings: warnings, errors: errors, messages: messages)
        result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
        delete_old_comment!(except: result[:id])
      else
        delete_old_comment!
      end

      # Now, set the pull request status
      submit_pull_request_status!(warnings: warnings,
                                    errors: errors,
                               details_url: result['html_url'])
    end

    def submit_pull_request_status!(warnings: nil, errors: nil, details_url: nil)
      status = (errors.count == 0 ? 'success' : 'failure')
      client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
        description: generate_github_description(warnings: warnings, errors: errors),
        context: "KrauseFx/danger",
        target_url: details_url
      })
    end

    # Get rid of the previously posted comment, to only have the latest one
    def delete_old_comment!(except: nil)
      issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
      issues.each do |issue|
        next unless issue[:body].gsub(/\s+/, "").include?("Generatedby<ahref=")
        next if issue[:id] == except
        client.delete_comment(ci_source.repo_slug, issue[:id])
      end
    end

    def generate_github_description(warnings: nil, errors: nil)
      if errors.count > 0
        "danger found errors"
      elsif warnings.count > 0
        "⚠️ danger found warnings, merge with caution"
      else
        "danger was successful"
      end
    end

    def generate_comment(warnings: nil, errors: nil, messages: nil)
      require 'erb'

      @warnings = warnings
      @errors = errors
      @messages = messages

      md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/github.md.erb")
      comment = ERB.new(File.read(md_template)).result(binding) # http://www.rrn.dk/rubys-erb-templating-system
      return comment
    end
  end
end
