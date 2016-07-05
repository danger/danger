require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Adds :doc & :spec_docs
require_relative "rake/dsl_generator"

RSpec::Core::RakeTask.new(:specs)

task default: :spec

task :spec do
  Rake::Task["specs"].invoke
  Rake::Task["rubocop"].invoke
  # Rake::Task['spec_docs'].invoke
end

desc "Run RuboCop on the lib/specs directory"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = Dir.glob(["lib/**/*.rb", "spec/**/*.rb"]) - Dir.glob(["spec/fixtures/**/*", "lib/danger/plugin_support/plugin_parser.rb"])
end

task :test do
  sh "fastlane test"
end

task :push do
  sh "fastlane release"
end
