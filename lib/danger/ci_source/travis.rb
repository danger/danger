# http://docs.travis-ci.com/user/osx-ci-environment/
# http://docs.travis-ci.com/user/environment-variables/
require "danger/request_sources/github/github"

module Danger
  # ### CI Setup
  # You need to edit your `.travis.yml` to include `bundle exec danger`. If you already have
  # a `script:` section then we recommend adding this command at the end of the script step: `- bundle exec danger`.
  #
  #  Otherwise, add a `before_script` step to the root of the `.travis.yml` with `bundle exec danger`
  #
  #  ```ruby
  #    before_script:
  #      - bundle exec danger
  #  ```
  #
  # Adding this to your `.travis.yml` allows Danger to fail your build, both on the TravisCI website and within your Pull Request.
  # With that set up, you can edit your job to add `bundle exec danger` at the build action.
  #
  # _Note:_ Travis CI defaults to using an older version of Ruby, so you may need to add `rvm: 2.0.0` to the root your `.travis.yml`.
  #
  # ### Token Setup
  #
  # You need to add the `DANGER_GITHUB_API_TOKEN` environment variable, to do this,
  # go to your repo's settings, which should look like: `https://travis-ci.org/[user]/[repo]/settings`.
  #
  # If you have an open source project, you should ensure "Display value in build log" enabled, so that PRs from forks work.
  #
  class Travis < CI
    def self.validates_as_ci?(env)
      env.key? "HAS_JOSH_K_SEAL_OF_APPROVAL"
    end

    def self.validates_as_pr?(env)
      exists = ["TRAVIS_PULL_REQUEST", "TRAVIS_REPO_SLUG"].all? { |x| env[x] && !env[x].empty? }
      exists && env["TRAVIS_PULL_REQUEST"].to_i > 0
    end

    def supported_request_sources
      @supported_request_sources ||= [Danger::RequestSources::GitHub]
    end

    def initialize(env)
      self.repo_slug = env["TRAVIS_REPO_SLUG"]
      if env["TRAVIS_PULL_REQUEST"].to_i > 0
        self.pull_request_id = env["TRAVIS_PULL_REQUEST"]
      end
      self.repo_url = GitRepo.new.origins # Travis doesn't provide a repo url env variable :/
    end
  end
end
