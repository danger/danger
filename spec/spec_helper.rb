$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "danger"
require "webmock"
require "webmock/rspec"
require "json"

require "support/env_helper"
require "support/gitlab_helper"

RSpec.configure do |config|
  config.filter_gems_from_backtrace "bundler"
  config.include Danger::Support::EnvHelper
  config.include Danger::Support::GitLabHelper
end

# Now that we could be using Danger's plugins in Danger
Danger::Plugin.clear_external_plugins

WebMock.disable_net_connect!(allow: "coveralls.io")

def make_temp_file(contents)
  file = Tempfile.new("dangefile_tests")
  file.write contents
  file
end

# rubocop:disable Lint/NestedMethodDefinition
def testing_ui
  @output = StringIO.new
  def @output.winsize
    [20, 9999]
  end

  cork = Cork::Board.new(out: @output)
  def cork.string
    out.string.gsub(/\e\[([;\d]+)?m/, "")
  end
  cork
end
# rubocop:enable Lint/NestedMethodDefinition

def testing_dangerfile(kind=nil)
  kind = kind.nil? ? :github : kind.to_symbol
  env = Danger::EnvironmentManager.new(stub_env(kind))
  dm = Danger::Dangerfile.new(env, testing_ui)
end

def fixture(file)
  File.read("spec/fixtures/#{file}.json")
end

def comment_fixture(file)
  File.read("spec/fixtures/#{file}.html")
end

def diff_fixture(file)
  File.read("spec/fixtures/#{file}.diff")
end

def violation(message)
  Danger::Violation.new(message, false)
end

def violations(messages)
  messages.map { |s| violation(s) }
end
