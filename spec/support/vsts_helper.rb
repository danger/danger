module Danger
  module Support
    module VSTSHelper
      def stub_env
        {
          "DANGER_VSTS_HOST" => "https://example.visualstudio.com/example",
          "DANGER_VSTS_API_TOKEN" => "a_token",
          "BUILD_BUILDID" => "3",
          "SYSTEM_PULLREQUEST_PULLREQUESTID" => "1",
          "SYSTEM_TEAMPROJECT" => "example",
          "BUILD_REPOSITORY_URI" => "https://example.visualstudio.com/_git/example"
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
    end
  end
end
