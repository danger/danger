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
      comment_result = {}

      if (warnings + errors + messages).empty?
        # Just remove the comment, if there's nothing to say.
        delete_old_comments!
      else
        body = generate_comment(warnings: warnings, errors: errors, messages: messages)
        comment_result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
        delete_old_comments!(except: comment_result[:id])
      end

      # Now, set the pull request status.
      # Note: this can terminate the entire process.
      submit_pull_request_status!(warnings: warnings,
                                    errors: errors,
                               details_url: comment_result['html_url'])
    end

    def submit_pull_request_status!(warnings: nil, errors: nil, details_url: nil)
      status = (errors.count == 0 ? 'success' : 'failure')
      message = generate_github_description(warnings: warnings, errors: errors)
      client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
        description: message,
        context: "KrauseFx/danger",
        target_url: details_url
      })
    rescue
      # This usually means the user has no commit access to this repo
      # That's always the case for open source projects where you can only
      # use a read-only GitHub account
      if errors.count > 0
        # We need to fail the actual build here
        abort("\nDanger has failed this build. \nFound #{errors.count} error(s) and I don't have write access to the PR set a PR status.")
      else
        puts message
      end
    end

    # Get rid of the previously posted comment, to only have the latest one
    def delete_old_comments!(except: nil)
      issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
      issues.each do |issue|
        next unless issue[:body].include?("generated_by_danger")
        next if issue[:id] == except
        client.delete_comment(ci_source.repo_slug, issue[:id])
      end
    end

    def generate_github_description(warnings: nil, errors: nil)
      if errors.empty? && warnings.empty?
        compliment = ["Well done.", "Congrats.", "Woo!",
                      "Yay.", "Jolly good show.", "Good on 'ya.", "Nice work."]
        "All green. #{compliment.sample}"
      else
        message = "⚠ "
        message += "#{errors.count} Error#{errors.count == 1 ? '' : 's'}. " unless errors.empty?
        message += "#{warnings.count} Warning#{warnings.count == 1 ? '' : 's'}. " unless warnings.empty?
        message += "Don't worry, everything is fixable."
      end
    end

    def generate_comment(warnings: nil, errors: nil, messages: nil)
      require 'erb'

      md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/github.md.erb")

      # erb: http://www.rrn.dk/rubys-erb-templating-system
      # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
      @tables = [
        { name: "Error", emoji: "no_entry_sign", content: errors },
        { name: "Warning", emoji: "warning", content: warnings },
        { name: "Message", emoji: "book", content: messages }
      ]
      return ERB.new(File.read(md_template), 0, "-").result(binding)
    end
  end
end
