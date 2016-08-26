# coding: utf-8
require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class BitbucketServer < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def initialize(ci_source, environment)
         self.ci_source = ci_source
         self.environment = environment

         @username = @environment["DANGER_BITBUCKETSERVER_USERNAME"]
         @password = @environment["DANGER_BITBUCKETSERVER_PASSWORD"]
      end

      def validates_as_ci?
        # TODO ???
        true
      end
      
      def validates_as_api_source?
        @username && !@username.empty? && @password && !@password.empty?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host ||= @environment["DANGER_BITBUCKETSERVER_HOST"]
      end

      def pr_api_endpoint
        project, slug = ci_source.repo_slug.split("/")
        "https://#{host}/rest/api/1.0/projects/#{project}/repos/#{slug}/pull-requests/#{ci_source.pull_request_id}"
      end

      def fetch_details
        self.pr_json = get_json(URI(pr_api_endpoint))
      end

      def setup_danger_branches
        base_commit = self.pr_json[:toRef][:latestCommit]
        head_commit = self.pr_json[:fromRef][:latestCommit]

        # Next, we want to ensure that we have a version of the current branch at a known location
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def organisation
        nil
      end
      
      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: 'danger')
        delete_old_comments(danger_id: danger_id)
        
        comment = generate_description(warnings: warnings, errors: errors)
        comment += "\n\n"
        comment += generate_comment(warnings: warnings,
                                     errors: errors,
                                   messages: messages,
                                  markdowns: markdowns,
                        previous_violations: {},
                                  danger_id: danger_id,
                                   template: "bitbucket_server")

        post(URI("#{pr_api_endpoint}/comments"), {text: comment}.to_json)
      end

      def delete_old_comments(danger_id: 'danger')
        uri = URI("#{pr_api_endpoint}/activities?limit=1000")
        comments = get_json(uri)[:values]
          .select { |v| v[:action] == "COMMENTED" }
          .map { |v| v[:comment] }
          .select { |c| c[:text] =~ /generated_by_#{danger_id}/ }
          .each { |c| delete(URI("#{pr_api_endpoint}/comments/#{c[:id]}?version=#{c[:version]}")) }
      end

      def get_json(uri)
        req = Net::HTTP::Get.new(uri.request_uri, {'Content-Type' =>'application/json'})
        req.basic_auth @username, @password
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
          http.request(req)
        end
        JSON.parse(res.body, symbolize_names: true)
      end

      def post(uri, body)
        req = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
        req.basic_auth @username, @password
        req.body = body
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
          http.request(req)
        end
      end
      
      def delete(uri)
        req = Net::HTTP::Delete.new(uri.request_uri, {'Content-Type' =>'application/json'})
        req.basic_auth @username, @password
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
          http.request(req)
        end
      end
      
    end
  end
end
