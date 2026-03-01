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
    end
  end
end
