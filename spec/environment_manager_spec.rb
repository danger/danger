require 'spec_helper'
require 'danger/environment_manager'

describe Danger::EnvironmentManager do
  it 'raises without enough info in the ENV' do
    expect {
      Danger::EnvironmentManager.new({ "KEY" => "VALUE" })
    }.to raise_error("Could not find a CI source")
  end

  it 'creates a travis CI attr' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.travis).to be_truthy
  end

  it 'creates a circle CI attr' do
    env = { "CIRCLE" => "true", "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.circle).to be_truthy
  end

  it 'creates a GitHub attr' do
    env = { "HAS_JOSH_K_SEAL_OF_APPROVAL" => "true" }
    e = Danger::EnvironmentManager.new(env)
    expect(e.github).to be_truthy
  end

end
