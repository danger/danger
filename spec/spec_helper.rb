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
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Custom
  config.include Danger::Support::GitLabHelper, host: :gitlab
  config.include Danger::Support::GitHubHelper, host: :github
  config.include Danger::Support::BitbucketServerHelper, host: :bitbucket_server
  config.include Danger::Support::BitbucketCloudHelper, host: :bitbucket_cloud
  config.include Danger::Support::VSTSHelper, host: :vsts
  config.include Danger::Support::CIHelper, use: :ci_helper
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
  @err = StringIO.new

  def @output.winsize
    [20, 9999]
  end

  cork = Cork::Board.new(out: @output, err: @err)
  def cork.string
    out.string.gsub(/\e\[([;\d]+)?m/, "")
  end

  def cork.err_string
    err.string.gsub(/\e\[([;\d]+)?m/, "")
  end

  cork
end
# rubocop:enable Lint/NestedMethodDefinition

def testing_dangerfile(env = stub_env)
  env_manager = Danger::EnvironmentManager.new(env, testing_ui)
  dm = Danger::Dangerfile.new(env_manager, testing_ui)
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

def violation_factory(message, sticky: false, file: nil, line: nil, **hash_args)
  Danger::Violation.new(message, sticky, file, line, **hash_args)
end

def violations_factory(messages, sticky: false)
  messages.map { |s| violation_factory(s, sticky: sticky) }
end

def markdown_factory(message)
  Danger::Markdown.new(message)
end

def markdowns_factory(messages)
  messages.map { |s| markdown_factory(s) }
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

      Dir.mkdir(dir + "/subdir")

      yield dir
    end
  end
end
