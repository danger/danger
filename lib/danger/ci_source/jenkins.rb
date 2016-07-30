# https://wiki.jenkins-ci.org/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-JenkinsSetEnvironmentVariables
# https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin

module Danger
  # https://jenkins-ci.org

  # ### CI Setup
  #
  # Ah Jenkins, so many memories. So, if you're using Jenkins, you're hosting your own environment. You
  # will want to be using the [GitHub pull request builder plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin)
  # in order to ensure that you have the build environment set up for PR integration.
  #
  # With that set up, you can edit your job to add `bundle exec danger` at the build action.
  #
  # ### Token Setup
  #
  # As you own the machine, it's up to you to add the enviroment variable for the `DANGER_GITHUB_API_TOKEN`.
  #
  class Jenkins < CI
    def self.validates_as_ci?(env)
      env.key? "JENKINS_URL"
    end

    def self.validates_as_pr?(env)
      ["ghprbPullId"].all? { |x| env[x] }
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_url = env["GIT_URL"]
      self.pull_request_id = env["ghprbPullId"]

      repo_matches = self.repo_url.match(%r{([\/:])([^\/]+\/[^\/.]+)(?:.git)?$})
      self.repo_slug = repo_matches[2] unless repo_matches.nil?
    end
  end
end
