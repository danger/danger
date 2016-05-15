$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'danger'
require 'webmock'
require 'webmock/rspec'
require 'json'

WebMock.disable_net_connect!(allow: 'coveralls.io')

def make_temp_file(contents)
  file = Tempfile.new('dangefile_tests')
  file.write contents
  file
end

def stub_ci
  env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
  Danger::CISource::CircleCI.new(env)
end

def fixture(file)
  File.read("spec/fixtures/#{file}.json")
end

def comment_fixture(file)
  File.read("spec/fixtures/#{file}.html")
end

def violation(message)
  Danger::Violation.new(message, false)
end

def violations(messages)
  messages.map { |s| violation(s) }
end
