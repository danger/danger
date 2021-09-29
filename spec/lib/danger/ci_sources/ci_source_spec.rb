require "danger/ci_source/ci_source"

RSpec.describe Danger::CI do
  describe ".available_ci_sources" do
    it "returns list of CI subclasses" do
      expect(described_class.available_ci_sources.map(&:to_s)).to match_array(
        [
          "Danger::Appcenter",
          "Danger::AppVeyor",
          "Danger::AzurePipelines",
          "Danger::Bamboo",
          "Danger::BitbucketPipelines",
          "Danger::Bitrise",
          "Danger::Buddybuild",
          "Danger::Buildkite",
          "Danger::CircleCI",
          "Danger::Cirrus",
          "Danger::CodeBuild",
          "Danger::Codefresh",
          "Danger::Codemagic",
          "Danger::Codeship",
          "Danger::Concourse",
          "Danger::DotCi",
          "Danger::Drone",
          "Danger::GitHubActions",
          "Danger::GitLabCI",
          "Danger::Jenkins",
          "Danger::LocalGitRepo",
          "Danger::LocalOnlyGitRepo",
          "Danger::Screwdriver",
          "Danger::Semaphore",
          "Danger::Surf",
          "Danger::TeamCity",
          "Danger::Travis",
          "Danger::VSTS",
          "Danger::XcodeCloud",
          "Danger::XcodeServer"
        ]
      )
    end
  end
end
