# rubocop:disable Metrics/ModuleLength

module Danger
  module Support
    module CIHelper
      def github_token
        { "DANGER_GITHUB_API_TOKEN" => "1234567890" * 4 }
      end

      def with_bitrise_setup_and_is_a_pull_request
        system_env = {
          "BITRISE_IO" => "true",
          "BITRISE_PULL_REQUEST" => "42"
        }

        yield(system_env)
      end

      def with_buildkite_setup_and_is_a_pull_request
        system_env = {
          "BUILDKITE" => "true",
          "BUILDKITE_PULL_REQUEST_REPO" => "true",
          "BUILDKITE_PULL_REQUEST" => "42"
        }

        yield(system_env)
      end

      def with_circle_setup_and_is_a_pull_request
        system_env = {
          "CIRCLE_BUILD_NUM" => "1589",
          "CI_PULL_REQUEST" => "https://circleci.com/gh/danger/danger/1589",
          "CIRCLE_CI_API_TOKEN" => "circle api token",
          "CIRCLE_PROJECT_USERNAME" => "danger",
          "CIRCLE_PROJECT_REPONAME" => "danger"
        }

        yield(system_env)
      end

      def with_drone_setup_and_is_a_pull_request
        system_env = {
          "DRONE_REPO_NAME" => "danger",
          "DRONE_REPO_OWNER" => "danger",
          "DRONE_PULL_REQUEST" => "42"
        }

        yield(system_env)
      end

      def with_gitlabci_setup_and_is_a_pull_request
        system_env = {
          "GITLAB_CI" => "true",
          "CI_MERGE_REQUEST_ID" => "42",
          "CI_PROJECT_ID" => "danger/danger"
        }

        yield(system_env)
      end

      def with_jenkins_setup_github_and_is_a_pull_request
        system_env = {
          "JENKINS_URL" => "https://ci.swift.org/job/oss-swift-incremental-RA-osx/lastBuild/",
          "ghprbPullId" => "42"
        }

        yield(system_env)
      end

      def with_jenkins_setup_gitlab_and_is_a_pull_request
        system_env = {
          "JENKINS_URL" => "https://ci.swift.org/job/oss-swift-incremental-RA-osx/lastBuild/",
          "gitlabMergeRequestId" => "42"
        }

        yield(system_env)
      end

      def with_localgitrepo_setup
        system_env = {
          "DANGER_USE_LOCAL_GIT" => "true"
        }

        yield(system_env)
      end

      def with_semaphore_setup_and_is_a_pull_request
        system_env = {
          "SEMAPHORE" => "true",
          "SEMAPHORE_REPO_SLUG" => "danger/danger",
          "PULL_REQUEST_NUMBER" => "42"
        }

        yield(system_env)
      end

      def with_surf_setup_and_is_a_pull_request
        system_env = {
          "SURF_REPO" => "true",
          "SURF_NWO" => "danger/danger"
        }

        yield(system_env)
      end

      def with_teamcity_setup_github_and_is_a_pull_request
        system_env = {
          "TEAMCITY_VERSION" => "1.0.0",
          "GITHUB_PULL_REQUEST_ID" => "42",
          "GITHUB_REPO_URL" => "https://github.com/danger/danger"
        }

        yield(system_env)
      end

      def with_teamcity_setup_gitlab_and_is_a_pull_request
        system_env = {
          "TEAMCITY_VERSION" => "1.0.0",
          "GITLAB_REPO_SLUG" => "danger/danger",
          "GITLAB_PULL_REQUEST_ID" => "42",
          "GITLAB_REPO_URL" => "gitlab.com/danger/danger"
        }

        yield(system_env)
      end

      def with_travis_setup_and_is_a_pull_request(request_source: nil)
        system_env = {
          "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
          "TRAVIS_PULL_REQUEST" => "42",
          "TRAVIS_REPO_SLUG" => "orta/orta"
        }

        if request_source == :github
          system_env.merge!(github_token)
        end

        yield(system_env)
      end

      def with_xcodeserver_setup_and_is_a_pull_request
        system_env = {
          "XCS_BOT_NAME" => "Danger BuildaBot"
        }

        yield(system_env)
      end

      def we_dont_have_ci_setup
        yield({})
      end

      def not_a_pull_request
        system_env = {
          "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true",
          "TRAVIS_REPO_SLUG" => "orta/orta"
        }

        yield(system_env)
      end
    end
  end
end
