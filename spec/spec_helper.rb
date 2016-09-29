$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path("../..", __FILE__)

# Needs to be required and started before danger
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "danger"
require "webmock"
require "webmock/rspec"
require "json"

Dir["spec/support/**/*.rb"].each { |file| require(file) }

RSpec.configure do |config|
  config.filter_gems_from_backtrace "bundler"
  config.include Danger::Support::GitLabHelper, host: :gitlab
  config.include Danger::Support::GitHubHelper, host: :github
  config.include Danger::Support::BitbucketServerHelper, host: :bitbucket_server
  config.include Danger::Support::BitbucketCloudHelper, host: :bitbucket_cloud
  config.include Danger::Support::CIHelper, use: :ci_helper

  config.run_all_when_everything_filtered = true
  config.filter_run focus: true
  config.order = :random
  Kernel.srand config.seed
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

def testing_dangerfile
  env = Danger::EnvironmentManager.new(stub_env, testing_ui)
  dm = Danger::Dangerfile.new(env, testing_ui)
end

def fixture_txt(file)
  File.read("spec/fixtures/#{file}.txt")
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

def violation(message, sticky: false)
  Danger::Violation.new(message, sticky)
end

def violations(messages, sticky: false)
  messages.map { |s| violation(s, sticky: sticky) }
end

def markdown(message)
  Danger::Markdown.new(message)
end

def markdowns(messages)
  messages.map { |s| markdown(s) }
end

def with_git_repo(origin: "git@github.com:artsy/eigen")
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      `git init`
      File.open(dir + "/file1", "w") {}
      `git add .`
      `git commit -m "ok"`

      `git checkout -b new --quiet`
      File.open(dir + "/file2", "w") {}
      `git add .`
      `git commit -m "another"`
      `git remote add origin #{origin}`

      yield
    end
  end
end
