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
          "DRONE_REPO" => "k0nserv/danger-test",
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

      def with_gitlab_git_repo
        Dir.mktmpdir do |dir|
          Dir.chdir dir do
            `git init`
            File.open(dir + "/file1", "w") {}
            `git add .`
            `git commit -m "ok"`

            `git checkout -b new`
            File.open(dir + "/file2", "w") {}
            `git add .`
            `git commit -m "another"`
            `git remote add origin git@gitlab.com:k0nserv/danger-test.git`

            yield
          end
        end
      end
    end
  end
end
