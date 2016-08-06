module Danger
  module Support
    module EnvHelper
      def stub_env(kind)
        if kind == :github
          {
            "DANGER_GITHUB_API_TOKEN" => "abc123",
            "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
            "TRAVIS_PULL_REQUEST" => "800",
            "TRAVIS_REPO_SLUG" => "artsy/eigen",
            "TRAVIS_COMMIT_RANGE" => "759adcbd0d8f...13c4dc8bb61d",
            "DANGER_GITHUB_API_TOKEN" => "hi"
          }
        elsif kind == :gitlab
          {
            "DANGER_GITLAB_API_TOKEN" => "abc123",
            "DRONE" => true,
            "DRONE_REPO" => "k0nserv/danger-test",
            "DRONE_PULL_REQUEST" => "593728",
            "DANGER_GITLAB_API_TOKEN" => "a86e56d46ac78b"
          }
        else
          nil
        end
      end

      def stub_ci(kind)
        if kind == :github
          env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
          Danger::CircleCI.new(env)
        elsif kind == :gitlab
          Danger::Drone.new(stub_env(:gitlab))
        else
          nil
        end
      end

      def stub_request_source(kind)
        if kind == :github
          Danger::RequestSources::GitHub.new(stub_ci(:github), stub_env(:github))
        elsif kind == :gitlab
          Danger::RequestSources::GitLab.new(stub_ci(:gitlab), stub_env(:gitlab))
        else
          nil
        end
      end
    end
  end
end
