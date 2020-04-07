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

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency "claide", "~> 1.0"
  spec.add_runtime_dependency "claide-plugins", ">= 0.9.2"
  spec.add_runtime_dependency "git", "~> 1.6"
  spec.add_runtime_dependency "colored2", "~> 3.1"
  spec.add_runtime_dependency "faraday", ">= 0.9.0", "< 2.0"
  spec.add_runtime_dependency "faraday-http-cache", "~> 2.0"
  spec.add_runtime_dependency "kramdown", "~> 2.0"
  spec.add_runtime_dependency "kramdown-parser-gfm", "~> 1.0"
  spec.add_runtime_dependency "octokit", "~> 4.7"
  spec.add_runtime_dependency "terminal-table", "~> 1"
  spec.add_runtime_dependency "cork", "~> 0.1"
  spec.add_runtime_dependency "no_proxy_fix"
end
# rubocop:enable Metrics/BlockLength
