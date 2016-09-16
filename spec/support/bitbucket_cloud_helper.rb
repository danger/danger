module Danger
  module Support
    module BitbucketCloudHelper
      def stub_env
        {
          "DANGER_BITBUCKETCLOUD_USERNAME" => "a.name",
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

      def with_git_repo
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
            `git remote add origin git@stash.example.com:artsy/eigen`

            yield
          end
        end
      end
    end
  end
end
