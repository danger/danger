# coding: utf-8
require 'rest'
require 'json'
require 'base64'
require 'octokit'

module Danger
  class GitHub
    attr_accessor :ci_source, :pr_json, :environment

    def initialize(ci_source, environment)
      self.ci_source = ci_source
      self.environment = environment
    end

    def client
      token = @environment["DANGER_GITHUB_API_TOKEN"]
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
      comment_result = {}
      if (warnings + errors + messages).empty?
        # Don't override comment_result, which is fine to nil
        # though to the create_status API.
        delete_old_comment!
      else
        body = generate_comment(warnings: warnings, errors: errors, messages: messages)
        comment_result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
        delete_old_comment!(except: comment_result[:id])
      end

      # Now, set the pull request status, note, this can
      # terminate the entire process.
      submit_pull_request_status!(warnings: warnings,
                                    errors: errors,
                               details_url: comment_result['html_url'])
    end

    def submit_pull_request_status!(warnings: nil, errors: nil, details_url: nil)
      status = (errors.count == 0 ? 'success' : 'failure')
      client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
        description: generate_github_description(warnings: warnings, errors: errors),
        context: "KrauseFx/danger",
        target_url: details_url
      })
    rescue => ex
      # This usually means the user has no commit access to this repo
      # That's always the case for open source projects where you can only
      # use a read-only GitHub account
      if errors.count > 0
        # We need to fail the actual build here
        abort("danger found #{errors.count} error(s) and doesn't have write access to the PR")
      end
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
      if errors.empty? && warnings.empty?
        "Everything is good."
      else
        message = "⚠ "
        message += "#{errors.count} Error#{errors.count == 1 ? "" : "s" }. " unless errors.empty?
        message += "#{warnings.count} Warning#{warnings.count == 1 ? "" : "s" }. "unless warnings.empty?
        message += "Don't worry, everything is fixable."
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
