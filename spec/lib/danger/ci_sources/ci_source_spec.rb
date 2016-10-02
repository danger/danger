require "danger/ci_source/ci_source"

RSpec.describe Danger::CI do
  describe ".available_ci_sources" do
    it "returns list of CI subclasses" do
      expect(described_class.available_ci_sources.map(&:to_s)).to match_array(
        [
          "Danger::LocalGitRepo",
          "Danger::Bitrise",
          "Danger::Buildkite",
          "Danger::CircleCI",
          "Danger::Drone",
          "Danger::GitLabCI",
          "Danger::Jenkins",
          "Danger::Semaphore",
          "Danger::Surf",
          "Danger::TeamCity",
          "Danger::Travis",
          "Danger::XcodeServer"
        ]
      )
    end
  end
end
