require "danger/version"
require "danger/dangerfile"
require "danger/environment_manager"
require "danger/runner"
require "danger/init"

require "claide"
require "colored"
require "pathname"

# Import all the Sources (CI, Request and SCM)
Dir[File.expand_path('danger/*source/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
