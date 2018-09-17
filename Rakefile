begin
  require "bundler/gem_tasks"
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:specs)
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  puts "Please use `bundle exec` to get all the rake commands"
end

task default: %w(rubocop spec)

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

desc "Runs chandler for current version"
task :chandler do
  lib = File.expand_path("../lib", __FILE__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  require "danger/version"
  if ENV["CHANDLER_GITHUB_API_TOKEN"]
    sh "bundle exec chandler push #{Danger::VERSION}"
  elsif ENV["DANGER_GITHUB_API_TOKEN"]
    sh "CHANDLER_GITHUB_API_TOKEN=#{ENV['DANGER_GITHUB_API_TOKEN']} bundle exec chandler push #{Danger::VERSION}"
  else
    puts "Skipping chandler due to no `CHANDLER_GITHUB_API_TOKEN` or `DANGER_GITHUB_API_TOKEN` in the ENV."
  end
end

Rake::Task["release"].enhance do
  Rake::Task["chandler"].invoke
end
