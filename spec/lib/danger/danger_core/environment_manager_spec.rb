require 'danger/danger_core/environment_manager'

describe Danger::EnvironmentManager do
  it 'raises without enough info in the ENV' do
    expect do
      Danger::EnvironmentManager.new({ "KEY" => "VALUE" })
    end.to raise_error("Could not find a CI source".red)
  end

  it 'stores travis in the source' do
    number = 123
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true", "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane", "TRAVIS_PULL_REQUEST" => number.to_s }
    e = Danger::EnvironmentManager.new(env)
    expect(e.ci_source.pull_request_id).to eq(number.to_s)
  end

  it 'stores circle in the source' do
    number = 800
    env = { "CIRCLE_BUILD_NUM" => "true", "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/#{number}" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.ci_source.pull_request_id).to eq(number.to_s)
  end

  it 'creates a GitHub attr' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true", "TRAVIS_REPO_SLUG" => "KrauseFx/fastlane", "TRAVIS_PULL_REQUEST" => 123.to_s }
    e = Danger::EnvironmentManager.new(env)
    expect(e.request_source).to be_truthy
  end

  it 'skips push runs and only runs for pull requests' do
    env = { "TRAVIS_REPO_SLUG" => "orta/danger", "TRAVIS_PULL_REQUEST" => "false", "HAS_JOSH_K_SEAL_OF_APPROVAL" => "1" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.ci_source).to eq(nil)
  end
end
