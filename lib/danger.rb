require "danger/version"
require "danger/danger_core/dangerfile"
require "danger/danger_core/environment_manager"
require "danger/commands/runner"
require "danger/plugin_support/plugin"
require "danger/core_ext/string"

require "claide"
require "colored"
require "pathname"
require "terminal-table"

# Import all the Sources (CI, Request and SCM)
Dir[File.expand_path('danger/*source/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

module Danger
  # @return [String] The path to the local gem directory
  def self.gem_path
    gem_name = "danger"
    unless Gem::Specification.find_all_by_name(gem_name).any?
      raise "Couldn't find gem directory for 'danger'"
    end
    return Gem::Specification.find_by_name(gem_name).gem_dir
  end
end
