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
            `git remote add origin git@github.com:artsy/eigen`

            yield
          end
        end
      end
    end
  end
end
