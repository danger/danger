source "https://rubygems.org"

gemspec

gem "bundler"
gem "chandler"
gem "danger-gitlab"
gem "danger-junit", "~> 0.5"
gem "faraday-http-cache", git: "https://github.com/sourcelevel/faraday-http-cache.git"
gem "fuubar", "~> 2.5"
gem "guard", "~> 2.16"
gem "guard-rspec", "~> 4.7"
gem "guard-rubocop", "~> 1.2"
gem "listen", "3.0.7"
gem "pry", "~> 0.13"
gem "pry-byebug"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.9"
gem "rspec_junit_formatter", "~> 0.4"
gem "rubocop", "~> 0.82"
gem "simplecov", "~> 0.18"
gem "webmock", "~> 2.1"
gem "yard", "~> 0.9.11"

if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("2.5.0")
   gem "gitlab", "< 4.14.1"
 end
