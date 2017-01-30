require "danger/version"
require "danger/danger_core/dangerfile"
require "danger/danger_core/environment_manager"
require "danger/commands/runner"
require "danger/plugin_support/plugin"
require "danger/core_ext/string"
require "danger/danger_core/executor"

require "claide"
require "colored2"
require "pathname"
require "terminal-table"
require "cork"

# Import all the Sources (CI, Request and SCM)
Dir[File.expand_path("danger/*source/*.rb", File.dirname(__FILE__))].each do |file|
  require file
end

module Danger
  GEM_NAME = "danger".freeze

  # @return [String] The path to the local gem directory
  def self.gem_path
    if Gem::Specification.find_all_by_name(GEM_NAME).empty?
      raise "Couldn't find gem directory for 'danger'"
    end
    return Gem::Specification.find_by_name(GEM_NAME).gem_dir
  end

  # @return [String] Latest version of Danger on https://rubygems.org
  def self.danger_outdated?
    require "danger/clients/rubygems_client"
    latest_version = RubyGemsClient.latest_danger_version

    if Gem::Version.new(latest_version) > Gem::Version.new(Danger::VERSION)
      latest_version
    else
      false
    end
  rescue StandardError => _e
    false
  end
end
