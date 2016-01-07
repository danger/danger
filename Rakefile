require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :test do
  sh "fastlane test"
end

task :push do
  sh "fastlane release"
end
