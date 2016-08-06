module Danger
  module Support
    module GitLabHelper
      def expected_headers
        {
          "Accept" => "application/json",
          "PRIVATE-TOKEN" => "DANGER_GITLAB_API_TOKEN"
        }
      end

      def stub_merge_request(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        escaped_slug = CGI.escape(slug)
        url = "https://gitlab.com/api/v3/projects/#{escaped_slug}/merge_request/#{merge_request_id}"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_commits(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        escaped_slug = CGI.escape(slug)
        url = "https://gitlab.com/api/v3/projects/#{escaped_slug}/merge_request/#{merge_request_id}/commits"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_comments(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        escaped_slug = CGI.escape(slug)
        url = "https://gitlab.com/api/v3/projects/#{escaped_slug}/merge_requests/#{merge_request_id}/notes"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end
    end
  end
end
