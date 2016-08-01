require "bundler/gem_tasks"
require "rubocop/rake_task"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:specs)
rescue LoadError
  puts "Please use `bundle exec` to get all the rake commands"
end

task default: :spec

desc "Danger's tests"
task :spec do
  Rake::Task["specs"].invoke
  Rake::Task["rubocop"].invoke
  Rake::Task["spec_docs"].invoke
end

desc "Run RuboCop on the lib/specs directory"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = Dir.glob(["lib/**/*.rb", "spec/**/*.rb"]) - Dir.glob(["spec/fixtures/**/*", "lib/danger/plugin_support/plugin_parser.rb"])
end

desc "Tests that the core documentation is up to snuff"
task :spec_docs do
  core_plugins = Dir.glob("lib/danger/danger_core/plugins/*.rb")
  sh "danger plugins lint #{core_plugins.join ' '}"
  sh "danger systems ci_docs"
end
