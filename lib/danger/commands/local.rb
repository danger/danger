module Danger
  class Local < Runner
    self.description = 'Run the Dangerfile locally.'
    self.command = 'local'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def run
      ENV["DANGER_USE_LOCAL_GIT"] = "YES"

      dm = Dangerfile.new
      dm.verbose = verbose
      dm.env = EnvironmentManager.new(ENV)

      puts "Found a PR merge commit on the project"
      puts "Creating a fake PR with the code from #{dm.env.ci_source.base_commit}..#{dm.env.ci_source.head_commit}"

      # TODO: try pinging original GitHub API ( without API key ) to get real details
      #       if that fails, then we can use this dummy information

      gh = GitHub.new(dm.env.ci_source, ENV)
      gh.pr_json = {
        head: { sha: "4324234" },
        title: "Test Pull Request",
        body: "Body of pull request",
        user: { login: `whoami`.strip }
      }
      dm.env.request_source = gh

      dm.env.scm = GitRepo.new
      dm.env.scm.diff_for_folder(".", dm.env.ci_source.base_commit, dm.env.ci_source.head_commit)
      dm.parse Pathname.new(@dangerfile_path)
    end
  end
end
