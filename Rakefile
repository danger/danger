require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:specs)

task default: :spec

task :spec do
  Rake::Task['specs'].invoke
  Rake::Task['rubocop'].invoke
end

desc 'Run RuboCop on the lib/specs directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
end

task :test do
  sh "fastlane test"
end

task :push do
  sh "fastlane release"
end
