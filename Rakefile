begin
  require "bundler/gem_tasks"
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:specs)
rescue LoadError
  puts "Please use `bundle exec` to get all the rake commands"
end

task default: :spec

desc "Danger's tests"
task :spec do
  Rake::Task["specs"].invoke
  Rake::Task["spec_docs"].invoke
end

desc "Tests that the core documentation is up to snuff"
task :spec_docs do
  core_plugins = Dir.glob("lib/danger/danger_core/plugins/*.rb")
  sh "danger plugins lint #{core_plugins.join ' '}"
  sh "danger systems ci_docs"
end

desc "I do this so often now, better to just handle it here"
task :guard do |task|
  sh "bundle exec guard"
end
