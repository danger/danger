module Danger
  module Support
    module BitbucketServerHelper
      def stub_env
        {
          "DANGER_BITBUCKETSERVER_HOST" => "stash.example.com",
          "DANGER_BITBUCKETSERVER_USERNAME" => "a.name",
          "DANGER_BITBUCKETSERVER_PASSWORD" => "a_password",
          "JENKINS_URL" => "http://jenkins.example.com/job/ios-check-pullrequest/",
          "GIT_URL" => "ssh://git@stash.example.com:7999/ios/fancyapp.git",
          "ghprbPullId" => "2080"
        }
      end

      def stub_ci
        Danger::Jenkins.new(stub_env)
      end

      def stub_request_source
        Danger::RequestSources::GitLab.new(stub_ci, stub_env)
      end

      def stub_pull_request
        raw_file = File.new("spec/fixtures/bitbucket_server_api/pr_response.json")
        url = "https://stash.example.com/rest/api/1.0/projects/ios/repos/fancyapp/pull-requests/2080"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end
    end
  end
end
