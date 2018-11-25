# https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-JenkinsSetEnvironmentVariables
# https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin
require "danger/request_sources/github/github"
require "danger/request_sources/gitlab"
require "danger/request_sources/bitbucket_server"
require "danger/request_sources/bitbucket_cloud"

module Danger
  # https://jenkins-ci.org

  # ### CI Setup
  # Ah Jenkins, so many memories. So, if you're using Jenkins, you're hosting your own environment.
  #
  # #### GitHub
  # You will want to be using the [GitHub pull request builder plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin)
  # in order to ensure that you have the build environment set up for PR integration.
  #
  # With that set up, you can edit your job to add `bundle exec danger` at the build action.
  #
  # ##### Pipeline
  # If your're using [pipelines](https://jenkins.io/solutions/pipeline/) you should be using the [GitHub branch source plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitHub+Branch+Source+Plugin)
  # for easy setup and handling of PRs.
  #
  # After you've set up the plugin, add a `sh 'bundle exec danger'` line in your pipeline script and make sure that build PRs is enabled.
  #
  # #### GitLab
  # You will want to be using the [GitLab Plugin](https://github.com/jenkinsci/gitlab-plugin)
  # in order to ensure that you have the build environment set up for MR integration.
  #
  # With that set up, you can edit your job to add `bundle exec danger` at the build action.
  #
  # #### General
  #
  # People occasionally see issues with Danger not classing your CI runs as a PR, to give you visibilty
  # the Jenkins side of Danger expects to see one of these env vars:
  # - ghprbPullId
  # - CHANGE_ID
  # - gitlabMergeRequestIid
  # - gitlabMergeRequestId
  #
  # ### Token Setup
  #
  # #### GitHub
  # As you own the machine, it's up to you to add the environment variable for the `DANGER_GITHUB_API_TOKEN`.
  #
  # #### GitLab
  # As you own the machine, it's up to you to add the environment variable for the `DANGER_GITLAB_API_TOKEN`.
  #
  class Jenkins < CI
    class EnvNotFound < StandardError
      def initialize
        super("ENV not found, please check your Jenkins. Related: https://stackoverflow.com/search?q=jenkins+env+null")
      end
    end

    def self.validates_as_ci?(env)
      env.key? "JENKINS_URL"
    end

    def self.validates_as_pr?(env)
      id = pull_request_id(env)
      !id.nil? && !id.empty?
    end

    def supported_request_sources
      @supported_request_sources ||= begin
        [
          Danger::RequestSources::GitHub,
          Danger::RequestSources::GitLab,
          Danger::RequestSources::BitbucketServer,
          Danger::RequestSources::BitbucketCloud
        ]
      end
    end

    def initialize(env)
      raise EnvNotFound.new if env.nil? || env.empty?

      self.repo_url = self.class.repo_url(env)
      self.pull_request_id = self.class.pull_request_id(env)

      repo_matches = self.repo_url.match(%r{(?:[\/:])projects\/([^\/.]+)\/repos\/([^\/.]+)}) # Bitbucket Server
      if repo_matches
        self.repo_slug = "#{repo_matches[1]}/#{repo_matches[2]}"
      else
        repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/]+)$})
        self.repo_slug = repo_matches[2].gsub(/\.git$/, "") unless repo_matches.nil?
      end
    end

    def self.pull_request_id(env)
      if env["ghprbPullId"]
        env["ghprbPullId"]
      elsif env["CHANGE_ID"]
        env["CHANGE_ID"]
      elsif env["gitlabMergeRequestIid"]
        env["gitlabMergeRequestIid"]
      else
        env["gitlabMergeRequestId"]
      end
    end

    def self.repo_url(env)
      if env["GIT_URL_1"]
        env["GIT_URL_1"]
      elsif env["CHANGE_URL"]
        change_url = env["CHANGE_URL"]
        case change_url
        when %r{\/pull\/} # GitHub
          matches = change_url.match(%r{(.+)\/pull\/[0-9]+})
          matches[1] unless matches.nil?
        when %r{\/merge_requests\/} # GitLab
          matches = change_url.match(%r{(.+)\/merge_requests\/[0-9]+})
          matches[1] unless matches.nil?
        when %r{\/pull-requests\/} # Bitbucket
          matches = change_url.match(%r{(.+)\/pull-requests\/[0-9]+})
          matches[1] unless matches.nil?
        else
          change_url
        end
      else
        env["GIT_URL"]
      end
    end
  end
end
