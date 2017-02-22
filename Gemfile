source "https://rubygems.org"

gemspec
gem "danger-gitlab"

if RUBY_VERSION == "2.3.1"
  # Lets be well lazy on GH releases OK? Can switch to real release after > 0.4.0
  gem "chandler", git: "https://github.com/orta/chandler.git", branch: "token"
end

gem "gitlab", "~> 3.7.0"

gem "danger-junit", "~> 0.5"
gem "rspec_junit_formatter", git: "https://github.com/JuanitoFatas/rspec_junit_formatter.git", branch: "dump-rspec_junit_formatter-failed-examples"
