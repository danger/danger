desc 'Generate documentation'
task :doc do
  puts "## Danger\n\n"

  dsls = public_api_methods
  loop_group(dsls)
end

desc 'Test that our public DSL is entirely documented'
task :spec_docs do
  dsls = public_api_methods
  docless = dsls.select { |method| method.docstring.empty? }
  raise "Found methods without documentation : #{docless.join ', '}" if docless.any?
end

def public_api_methods
  require 'yard'
  files = [
    "lib/danger/danger_core/dangerfile_dsl.rb",
    "lib/danger/scm_source/git_repo.rb",
  ]
  docs = YARD::Registry.load(files, true)

  danger_dsl = docs.at("Danger::Dangerfile::DSL").meths(visibility: :public)
  git_dsls = docs.at("Danger::GitRepoDSL").meths(visibility: :public)

  # Remove init functions
  (danger_dsl + git_dsls).reject { |m| m.name == :initialize }
end

def loop_group(methods)
  current_group = ""

  methods.each do |method|
    puts "#### #{method.group}\n" if method.group != current_group
    show_method(method)

    current_group = method.group
  end
end

def show_method(method)
  puts "- #{method.name}"

  raise "No docstring found" if method.docstring.empty?
  puts "  : #{method.docstring}"

  file, line = method.files.flatten
  puts "  : #{file} - #{line}"
  puts ""
end
