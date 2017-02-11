module Danger
  class LocalSetup
    attr_reader :dm, :cork

    def initialize(dangerfile, cork)
      @dm = dangerfile
      @cork = cork
    end

    def setup(verbose: false)
      source = dm.env.ci_source
      if source.nil? or source.repo_slug.empty?
        cork.puts "danger local failed because it only works with GitHub projects at the moment. Sorry.".red
        exit 0
      end

      gh = dm.env.request_source
      # We can use tokenless here, as it's running on someone's computer
      # and is IP locked, as opposed to on the CI.
      gh.support_tokenless_auth = true

      cork.puts "Running your Dangerfile against this PR - https://#{gh.host}/#{source.repo_slug}/pull/#{source.pull_request_id}"

      unless verbose
        cork.puts "Turning on --verbose"
        dm.verbose = true
      end

      cork.puts

      begin
        gh.fetch_details
      rescue Octokit::NotFound
        cork.puts "Local repository was not found on GitHub. If you're trying to test a private repository please provide a valid API token through " + "DANGER_GITHUB_API_TOKEN".yellow + " environment variable."
        return
      end

      yield
    end
  end
end
