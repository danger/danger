# coding: utf-8
require 'octokit'
require 'redcarpet'

module Danger
  module RequestSources
    class GitHub < RequestSource
      attr_accessor :pr_json, :issue_json, :support_tokenless_auth

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment
        self.support_tokenless_auth = false

        Octokit.auto_paginate = true
        @token = @environment['DANGER_GITHUB_API_TOKEN']
        if @environment['DANGER_GITHUB_API_HOST']
          Octokit.api_endpoint = @environment['DANGER_GITHUB_API_HOST']
        end
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host = @environment['DANGER_GITHUB_HOST'] || 'github.com'
      end

      def client
        raise 'No API token given, please provide one using `DANGER_GITHUB_API_TOKEN`' if !@token && !support_tokenless_auth
        @client ||= Octokit::Client.new(access_token: @token)
      end

      def markdown_parser
        @markdown_parser ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_intra_emphasis: true)
      end

      def setup_danger_branches
        # we can use a github specific feature here:
        base_commit = self.pr_json[:base][:sha]
        head_commit = self.pr_json[:head][:sha]

        # Next, we want to ensure that we have a version of the current branch at a known location
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
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

      # Sending data to GitHub
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: 'danger')
        comment_result = {}

        issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        editable_issues = issues.reject { |issue| issue[:body].include?("generated_by_#{danger_id}") == false }

        if editable_issues.empty?
          previous_violations = {}
        else
          comment = editable_issues.first[:body]
          previous_violations = parse_comment(comment)
        end

        if previous_violations.empty? && (warnings + errors + messages + markdowns).empty?
          # Just remove the comment, if there's nothing to say.
          delete_old_comments!(danger_id: danger_id)
        else
          body = generate_comment(warnings: warnings,
                                    errors: errors,
                                  messages: messages,
                                 markdowns: markdowns,
                       previous_violations: previous_violations,
                                 danger_id: danger_id)

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

      def submit_pull_request_status!(warnings: [], errors: [], details_url: [])
        status = (errors.count == 0 ? 'success' : 'failure')
        message = generate_github_description(warnings: warnings, errors: errors)

        latest_pr_commit_ref = self.pr_json[:head][:sha]

        if latest_pr_commit_ref.empty? || latest_pr_commit_ref.nil?
          raise "Couldn't find a commit to update its status".red
        end

        begin
          client.create_status(ci_source.repo_slug, latest_pr_commit_ref, status, {
            description: message,
            context: 'danger/danger',
            target_url: details_url
          })
        rescue
          # This usually means the user has no commit access to this repo
          # That's always the case for open source projects where you can only
          # use a read-only GitHub account
          if errors.count > 0
            # We need to fail the actual build here
            abort("\nDanger has failed this build. \nFound #{'error'.danger_pluralize(errors.count)} and I don't have write access to the PR set a PR status.")
          else
            puts message
          end
        end
      end

      # Get rid of the previously posted comment, to only have the latest one
      def delete_old_comments!(except: nil, danger_id: 'danger')
        issues = client.issue_comments(ci_source.repo_slug, ci_source.pull_request_id)
        issues.each do |issue|
          next unless issue[:body].include?("generated_by_#{danger_id}")
          next if issue[:id] == except
          client.delete_comment(ci_source.repo_slug, issue[:id])
        end
      end

      def random_compliment
        compliment = ['Well done.', 'Congrats.', 'Woo!',
                      'Yay.', 'Jolly good show.', "Good on 'ya.", 'Nice work.']
        compliment.sample
      end

      def generate_github_description(warnings: nil, errors: nil)
        if errors.empty? && warnings.empty?
          return "All green. #{random_compliment}"
        else
          message = "⚠ "
          message += "#{'Error'.danger_pluralize(errors.count)}. " unless errors.empty?
          message += "#{'Warning'.danger_pluralize(warnings.count)}. " unless warnings.empty?
          message += "Don't worry, everything is fixable."
          return message
        end
      end

      def generate_comment(warnings: [], errors: [], messages: [], markdowns: [], previous_violations: {}, danger_id: 'danger')
        require 'erb'

        md_template = File.join(Danger.gem_path, 'lib/danger/comment_generators/github.md.erb')

        # erb: http://www.rrn.dk/rubys-erb-templating-system
        # for the extra args: http://stackoverflow.com/questions/4632879/erb-template-removing-the-trailing-line
        @tables = [
          table('Error', 'no_entry_sign', errors, previous_violations),
          table('Warning', 'warning', warnings, previous_violations),
          table('Message', 'book', messages, previous_violations)
        ]
        @markdowns = markdowns
        @danger_id = danger_id

        return ERB.new(File.read(md_template), 0, '-').result(binding)
      end

      def table(name, emoji, violations, all_previous_violations)
        content = violations.map { |v| process_markdown(v) }.uniq
        kind = table_kind_from_title(name)
        previous_violations = all_previous_violations[kind] || []
        messages = content.map(&:message)
        resolved_violations = previous_violations.uniq - messages
        count = content.count
        { name: name, emoji: emoji, content: content, resolved: resolved_violations, count: count }
      end

      def parse_comment(comment)
        tables = parse_tables_from_comment(comment)
        violations = {}
        tables.each do |table|
          next unless table =~ %r{<th width="100%"(.*?)</th>}im
          title = Regexp.last_match(1)
          kind = table_kind_from_title(title)
          next unless kind

          violations[kind] = violations_from_table(table)
        end

        violations.reject { |_, v| v.empty? }
      end

      def violations_from_table(table)
        regex = %r{<td data-sticky="true">(?:<del>)?(.*?)(?:</del>)?\s*</td>}im
        table.scan(regex).flatten.map(&:strip)
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

      # @return [String] The organisation name, is nil if it can't be detected
      def organisation
        matched = self.issue_json[:repository_url].match(%r{repos\/(.*)\/})
        return matched[1] if matched
        nil
      rescue
        nil
      end

      # @return [Hash] with the information about the repo
      #   returns nil if the repo is not available
      def fetch_repository(organisation: nil, repository: nil)
        organisation ||= self.organisation
        return self.client.repo("#{organisation}/#{repository}")
      rescue Octokit::NotFound
        return nil # repo doesn't exist
      end

      # @return [Hash] with the information about the repo.
      #   This will automatically detect if the repo is capitalised
      #   returns nil if there is no danger repo
      def fetch_danger_repo(organisation: nil)
        data = nil
        data ||= fetch_repository(organisation: organisation, repository: "danger")
        data ||= fetch_repository(organisation: organisation, repository: "Danger")
        return data
      end

      # @return [String] A URL to the specific file, ready to be downloaded
      def file_url(organisation: nil, repository: nil, branch: 'master', path: nil)
        organisation ||= self.organisation
        "https://raw.githubusercontent.com/#{organisation}/#{repository}/#{branch}/#{path}"
      end
    end
  end
end
