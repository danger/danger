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
        uri = URI(pr_api_endpoint)
        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth @username, @password
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
          http.request(req)
        end
        self.pr_json = JSON.parse(res.body, symbolize_names: true)
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
        # TODO use a template
        # TODO parse and update old comments
        # TODO use tasks for errors?

        
        comment = generate_comment(warnings: warnings,
                                     errors: errors,
                                   messages: messages,
                                  markdowns: markdowns,
                        previous_violations: {},
                                  danger_id: danger_id,
                                   template: "bitbucket_server")

        uri = URI("#{pr_api_endpoint}/comments")
        req = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
        req.basic_auth @username, @password
        req.body = {text: comment}.to_json
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
          http.request(req)
        end
      end
    end
  end
end
