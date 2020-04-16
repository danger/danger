source "https://rubygems.org"

gemspec

gem "bundler"
gem "chandler" if RUBY_VERSION != "2.0.0"
gem "danger-gitlab"
gem "danger-junit", "~> 0.5"
gem "faraday-http-cache", git: "https://github.com/sourcelevel/faraday-http-cache.git"
gem "fuubar", "~> 2.5"
gem "guard", "~> 2.14"
gem "guard-rspec", "~> 4.7"
gem "guard-rubocop", "~> 1.2"
gem "listen", "3.0.7"
if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("2.4.0")
  gem "pry", "~> 0.10", "< 0.13"
else
  gem "pry", "~> 0.10"
end
gem "pry-byebug"
gem "rake", "~> 10.0"
gem "rspec", "~> 3.4"
gem "rspec_junit_formatter", "~> 0.2"
gem "rubocop", "~> 0.49.0"
gem "simplecov", "~> 0.12.0"
gem "webmock", "~> 2.1"
gem "yard", "~> 0.9.11"
if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("2.4.0")
  gem "byebug", "< 11.1.0"
  gem "gitlab", "< 4.14.0"
end
