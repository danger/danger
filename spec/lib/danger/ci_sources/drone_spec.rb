require "danger/ci_source/drone"

RSpec.describe Danger::Drone do
  describe "Drone >= 0.6" do
    it "validates when DRONE variable is set" do
      env = { "DRONE" => "true",
              "DRONE_REPO_NAME" => "danger",
              "DRONE_REPO_OWNER" => "danger",
              "DRONE_PULL_REQUEST" => 1 }
      expect(Danger::Drone.validates_as_ci?(env)).to be true
    end

    it "does not validate PR when DRONE_PULL_REQUEST is set to non int value" do
      env = { "CIRCLE" => "true",
              "DRONE_REPO_NAME" => "danger",
              "DRONE_REPO_OWNER" => "danger",
              "DRONE_PULL_REQUEST" => "maku" }
      expect(Danger::Drone.validates_as_pr?(env)).to be false
    end

    it "does not validate  PR when DRONE_PULL_REQUEST is set to non positive int value" do
      env = { "CIRCLE" => "true",
              "DRONE_REPO_NAME" => "danger",
              "DRONE_REPO_OWNER" => "danger",
              "DRONE_PULL_REQUEST" => -1 }
      expect(Danger::Drone.validates_as_pr?(env)).to be false
    end

    it "gets the repo address" do
      env = {
        "DRONE_REPO_NAME" => "danger",
        "DRONE_REPO_OWNER" => "orta"
      }

      result = Danger::Drone.new(env)

      expect(result.repo_slug).to eq("orta/danger")
    end

    it "gets out a repo slug and pull request number" do
      env = {
        "DRONE" => "true",
        "DRONE_PULL_REQUEST" => "800",
        "DRONE_REPO_NAME" => "eigen",
        "DRONE_REPO_OWNER" => "artsy"
      }
      result = Danger::Drone.new(env)

      expect(result).to have_attributes(
        repo_slug: "artsy/eigen",
        pull_request_id: "800"
      )
    end
  end

  it "does not validate when DRONE is not set" do
    env = { "CIRCLE" => "true" }
    expect(Danger::Drone.validates_as_ci?(env)).to be false
  end

  describe "Drone < 0.6" do
    it "validates when DRONE variable is set" do
      env = { "DRONE" => "true",
              "DRONE_REPO" => "danger/danger",
              "DRONE_PULL_REQUEST" => 1 }
      expect(Danger::Drone.validates_as_ci?(env)).to be true
    end

    it "does not validate PR when DRONE_PULL_REQUEST is set to non int value" do
      env = { "CIRCLE" => "true",
              "DRONE_REPO" => "danger/danger",
              "DRONE_PULL_REQUEST" => "maku" }
      expect(Danger::Drone.validates_as_pr?(env)).to be false
    end

    it "does not validate  PR when DRONE_PULL_REQUEST is set to non positive int value" do
      env = { "CIRCLE" => "true",
              "DRONE_REPO" => "danger/danger",
              "DRONE_PULL_REQUEST" => -1 }
      expect(Danger::Drone.validates_as_pr?(env)).to be false
    end

    it "gets the repo address" do
      env = {
        "DRONE_REPO" => "orta/danger"
      }

      result = Danger::Drone.new(env)

      expect(result.repo_slug).to eq("orta/danger")
    end

    it "gets out a repo slug and pull request number" do
      env = {
        "DRONE" => "true",
        "DRONE_PULL_REQUEST" => "800",
        "DRONE_REPO" => "artsy/eigen"
      }
      result = Danger::Drone.new(env)

      expect(result).to have_attributes(
        repo_slug: "artsy/eigen",
        pull_request_id: "800"
      )
    end
  end

  it "gets the pull request ID" do
    env = { "DRONE_PULL_REQUEST" => "2" }

    result = Danger::Drone.new(env)

    expect(result.pull_request_id).to eq("2")
  end
end
