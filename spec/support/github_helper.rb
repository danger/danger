module Danger
  module Support
    module GitHubHelper
      def expected_headers
        {
        }
      end

      def stub_env
        {
          "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
          "TRAVIS_PULL_REQUEST" => "800",
          "TRAVIS_REPO_SLUG" => "artsy/eigen",
          "TRAVIS_COMMIT_RANGE" => "759adcbd0d8f...13c4dc8bb61d",
          "DANGER_GITHUB_API_TOKEN" => "hi"
        }
      end

      def stub_ci
        env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
        Danger::CircleCI.new(env)
      end

      def stub_request_source
        Danger::RequestSources::GitHub.new(stub_ci, stub_env)
      end

      def stub_merge_request(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        escaped_slug = CGI.escape(slug)
        url = "https://gitlab.com/api/v3/projects/#{escaped_slug}/merge_request/#{merge_request_id}"
        WebMock.stub_request(:get, url).with(headers: expected_headers).to_return(raw_file)
      end

      def stub_merge_request_changes(fixture, slug, merge_request_id)
        raw_file = File.new("spec/fixtures/gitlab_api/#{fixture}.json")
        escaped_slug = CGI.escape(slug)
        url = "https://gitlab.com/api/v3/projects/#{escaped_slug}/merge_request/#{merge_request_id}/changes"
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
