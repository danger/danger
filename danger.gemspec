# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "danger/version"
Gem::Specification.new do |spec|
  spec.name          = "danger"
  spec.version       = Danger::VERSION
  spec.authors       = ["Orta Therox", "Juanito Fatas"]
  spec.email         = ["orta.therox@gmail.com", "katehuang0320@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = Danger::DESCRIPTION
  spec.description   = "Stop Saying 'You Forgot To…' in Code Review"
  spec.homepage      = "https://github.com/danger/danger"

  spec.files         = Dir["lib/**/*"] + %w(bin/danger README.md LICENSE)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_runtime_dependency "claide", "~> 1.0"
  spec.add_runtime_dependency "claide-plugins", ">= 0.9.2"
  spec.add_runtime_dependency "git", "~> 1"
  spec.add_runtime_dependency "colored2", "~> 3.1"
  spec.add_runtime_dependency "faraday", "~> 0.9"
  spec.add_runtime_dependency "faraday-http-cache", "~> 1.0"
  spec.add_runtime_dependency "octokit", "~> 4.7"
  spec.add_runtime_dependency "kramdown", "~> 1.5"
  spec.add_runtime_dependency "terminal-table", "~> 1"
  spec.add_runtime_dependency "cork", "~> 0.1"
  spec.add_runtime_dependency "no_proxy_fix"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.2"
  spec.add_development_dependency "webmock", "~> 2.1"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug"

  spec.add_development_dependency "rubocop", "~> 0.46.0"
  spec.add_development_dependency "yard", "~> 0.8"

  spec.add_development_dependency "listen", "3.0.7"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "guard-rubocop", "~> 1.2"
  spec.add_development_dependency "simplecov", "~> 0.12.0"
end
# rubocop:enable Metrics/BlockLength
