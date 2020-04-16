module Danger
  module Support
    module BitbucketCloudHelper
      def stub_env
        {
          "DANGER_BITBUCKETCLOUD_USERNAME" => "a.name",
          "DANGER_BITBUCKETCLOUD_UUID" => "c91be865-efc6-49a6-93c5-24e1267c479b",
          "DANGER_BITBUCKETCLOUD_PASSWORD" => "a_password",
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
        raw_file = File.new("spec/fixtures/bitbucket_cloud_api/pr_response.json")
        url = "https://api.bitbucket.org/2.0/repositories/ios/fancyapp/pullrequests/2080"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end

      def stub_pull_requests
        raw_file = File.new("spec/fixtures/bitbucket_cloud_api/prs_response.json")
        url = "https://api.bitbucket.org/2.0/repositories/ios/fancyapp/pullrequests?q=source.branch.name=%22feature_branch%22"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end

      def stub_access_token
        raw_file = File.new("spec/fixtures/bitbucket_cloud_api/oauth2_response.json")
        url = "https://bitbucket.org/site/oauth2/access_token"
        WebMock.stub_request(:post, url).to_return(raw_file)
      end
    end
  end
end
