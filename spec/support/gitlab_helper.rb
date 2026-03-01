module Danger
  module Support
    module GitLabHelper
      def expected_headers
        {
          "Accept" => "application/json",
          "PRIVATE-TOKEN" => stub_env["DANGER_GITLAB_API_TOKEN"]
        }
      end

      def stub_env
        {
          "DRONE" => true,
          "DRONE_REPO_OWNER" => "k0nserv",
          "DRONE_REPO_NAME" => "danger-test",
          "DRONE_PULL_REQUEST" => "593728",
          "DANGER_GITLAB_API_TOKEN" => "a86e56d46ac78b"
        }
      end

      def stub_ci
        Danger::Drone.new(stub_env)
      end

      def stub_request_source
        Danger::RequestSources::GitLab.new(stub_ci, stub_env)
      end

      def stub_merge_requests(fixture, slug)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        url = "https://gitlab.com/api/v4/projects/#{slug}/merge_requests?state=opened"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        url = "https://gitlab.com/api/v4/projects/#{slug}/merge_requests/#{merge_request_id}"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_changes(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        url = "https://gitlab.com/api/v4/projects/#{slug}/merge_requests/#{merge_request_id}/changes"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_commits(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        url = "https://gitlab.com/api/v4/projects/#{slug}/merge_requests/#{merge_request_id}/commits"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_comments(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        url = "https://gitlab.com/api/v4/projects/#{slug}/merge_requests/#{merge_request_id}/notes?per_page=100"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end
    end
  end
end
