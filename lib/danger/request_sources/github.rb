# coding: utf-8
require 'octokit'
require 'redcarpet'

module Danger
  class GitHub
    attr_accessor :ci_source, :pr_json, :issue_json, :environment, :base_commit, :head_commit, :support_tokenless_auth, :ignored_violations, :github_host

    def initialize(ci_source, environment)
      self.ci_source = ci_source
      self.environment = environment
      self.support_tokenless_auth = false

      Octokit.auto_paginate = true
      @token = @environment["DANGER_GITHUB_API_TOKEN"]
      self.github_host = @environment["DANGER_GITHUB_HOST"] || "github.com"
      if @environment["DANGER_GITHUB_API_HOST"]
        Octokit.api_endpoint = @environment["DANGER_GITHUB_API_HOST"]
      end
    end

    def client
      raise "No API given, please provide one using `DANGER_GITHUB_API_TOKEN`" if !@token && !support_tokenless_auth

      @client ||= Octokit::Client.new(
        access_token: @token
      )
    end

    def markdown_parser
      @markdown_parser ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    end

    def fetch_details
      self.pr_json = client.pull_request(ci_source.repo_slug, ci_source.pull_request_id)
      fetch_issue_details(self.pr_json)
      self.ignored_violations = ignored_violations_from_pr(self.pr_json)
    end

    def ignored_violations_from_pr(pr_json)
      pr_body = pr_json[:body]
      return [] if pr_body.nil?
      pr_body.chomp.scan(/>\s*danger\s*:\s*ignore\s*"(.*)"/i).flatten
    end

    def fetch_issue_details(pr_json)
      href = pr_json[:_links][:issue][:href]
      self.issue_json = client.get(href)
    end

    def base_commit
      self.pr_json[:base][:sha]
    end

    def head_commit
      self.pr_json[:head][:sha]
    end

    def branch_for_merge
      self.pr_json[:base][:ref]
    end

    def pr_title
      self.pr_json[:title].to_s
    end

    def pr_body
      self.pr_json[:body].to_s
    end

    def pr_author
      self.pr_json[:user][:login].to_s
    end

    def pr_labels
      self.issue_json[:labels].map { |l| l[:name] }
    end

    # Sending data to GitHub
    def update_pull_request!(warnings: nil, errors: nil, messages: nil)
      comment_result = {}

      issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
      editable_issues = issues.reject { |issue| issue[:body].include?("generated_by_danger") == false }

      if editable_issues.empty?
        previous_violations = {}
      else
        comment = editable_issues.first[:body]
        previous_violations = parse_comment(comment)
      end

      if previous_violations.empty? && (warnings + errors + messages).empty?
        # Just remove the comment, if there's nothing to say.
        delete_old_comments!
      else
        body = generate_comment(warnings: warnings, errors: errors, messages: messages, previous_violations: previous_violations)

        if editable_issues.empty?
          comment_result = client.add_comment(ci_source.repo_slug, ci_source.pull_request_id, body)
        else
          original_id = editable_issues.first[:id]
          comment_result = client.update_comment(ci_source.repo_slug, original_id, body)
        end
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
        context: "danger/danger",
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
        return "All green. #{compliment.sample}"
      else
        message = "⚠ "
        message += "#{errors.count} Error#{errors.count == 1 ? '' : 's'}. " unless errors.empty?
        message += "#{warnings.count} Warning#{warnings.count == 1 ? '' : 's'}. " unless warnings.empty?
        message += "Don't worry, everything is fixable."
        return message
      end
    end

    def generate_comment(warnings: [], errors: [], messages: [], previous_violations: {})
      require 'erb'

      md_template = File.join(Danger.gem_path, "lib/danger/comment_generators/github.md.erb")

      # erb: http://www.rrn.dk/rubys-erb-templating-system
      # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
      @tables = [
        table("Error", "no_entry_sign", errors, previous_violations),
        table("Warning", "warning", warnings, previous_violations),
        table("Message", "book", messages, previous_violations)
      ]
      return ERB.new(File.read(md_template), 0, "-").result(binding)
    end

    def table(name, emoji, violations, all_previous_violations)
      content = violations.map { |v| process_markdown(v) }
      kind = table_kind_from_title(name)
      previous_violations = all_previous_violations[kind] || []
      resolved_violations = previous_violations.reject { |s| content.include? s }
      { name: name, emoji: emoji, content: content, resolved: resolved_violations }
    end

    def parse_comment(comment)
      tables = parse_tables_from_comment(comment)
      violations = {}
      tables.each do |table|
        next unless table =~ %r{<th width="100%">(.*?)</th>}im
        title = Regexp.last_match(1)
        kind = table_kind_from_title(title)
        next unless kind

        violations[kind] = violations_from_table(table)
      end

      violations.reject { |k, v| v.empty? }
    end

    def violations_from_table(table)
      regex = %r{<td data-sticky="true">(<strike>)?(.*?)(</strike>)?\s*</td>}im
      table.scan(regex).map { |a| a[1] }.map(&:strip)
    end

    def table_kind_from_title(title)
      if title =~ /error/i
        :error
      elsif title =~ /warning/i
        :warning
      elsif title =~ /message/i
        :message
      end
    end

    def parse_tables_from_comment(comment)
      comment.split('</table>')
    end

    def process_markdown(violation)
      html = markdown_parser.render(violation.message)
      match = html.match(%r{^<p>(.*)</p>$})
      message = match.nil? ? html : match.captures.first
      Violation.new(message, violation.sticky)
    end
  end
end
