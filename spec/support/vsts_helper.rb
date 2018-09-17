module Danger
  module Support
    module VSTSHelper
      def stub_env
        {
          "DANGER_VSTS_HOST" => "https://example.visualstudio.com/example",
          "DANGER_VSTS_API_TOKEN" => "a_token",
          "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI" => "https://example.visualstudio.com",
          "BUILD_SOURCEBRANCH" => "refs/pull/1/merge",
          "BUILD_REPOSITORY_URI" => "https://example.visualstudio.com/_git/example",
          "BUILD_REASON" => "PullRequest",
          "BUILD_REPOSITORY_NAME" => "example",
          "SYSTEM_TEAMPROJECT" => "example",
          "BUILD_REPOSITORY_PROVIDER" => "TfsGit"
        }
      end

      def stub_ci
        Danger::VSTS.new(stub_env)
      end

      def stub_request_source
        Danger::RequestSources::VSTS.new(stub_ci, stub_env)
      end

      def stub_pull_request
        raw_file = File.new("spec/fixtures/vsts_api/pr_response.json")
        url = "https://example.visualstudio.com/example/_apis/git/repositories/example/pullRequests/1?api-version=3.0"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end

      def stub_get_comments_request_no_danger
        raw_file = File.new("spec/fixtures/vsts_api/no_danger_comments_response.json")
        url = "https://example.visualstudio.com/example/_apis/git/repositories/example/pullRequests/1/threads?api-version=3.0"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end

      def stub_get_comments_request_with_danger
        raw_file = File.new("spec/fixtures/vsts_api/danger_comments_response.json")
        url = "https://example.visualstudio.com/example/_apis/git/repositories/example/pullRequests/1/threads?api-version=3.0"
        WebMock.stub_request(:get, url).to_return(raw_file)
      end
    end
  end
end
