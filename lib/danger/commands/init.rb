# frozen_string_literal: true

require "danger/commands/init_helpers/interviewer"
require "danger/danger_core/dangerfile_generator"
require "danger/ci_source/local_git_repo"
require "yaml"
require "fileutils"

module Danger
  class Init < Runner
    self.summary = "Helps you set up Danger."
    self.command = "init"

    attr_accessor :ui

    def self.options
      [
        ["--impatient", "'I've not got all day here. Don't add any thematic delays please.'"],
        ["--mousey", "'Don't make me press return to continue the adventure.'"]
      ].concat(super)
    end

    def initialize(argv)
      @bot_name = "#{File.basename(Dir.getwd).split('.').first.capitalize}Bot"
      super
      @ui = Interviewer.new(cork)
      ui.no_delay = argv.flag?("impatient", false)
      ui.no_waiting = argv.flag?("mousey", false)
    end

    def run
      ui.say "\nOK, thanks #{ENV['LOGNAME']}, have a seat and we'll get you started.\n".yellow
      ui.pause 1

      @selected_ci = select_ci
      @github_actions = @selected_ci == "github actions"
      show_todo_state
      ui.pause 1.4

      setup_dangerfile
      if @github_actions
        setup_github_actions
      else
        setup_github_account
        setup_access_token
        setup_danger_ci
      end

      info
      thanks
    end

    def select_ci
      configurations = {
        "GitHub Actions" => [".github/workflows/*.{yml,yaml}"],
        "Travis CI" => [".travis.yml"],
        "CircleCI" => [".circleci/config.yml", ".circleci/config.yaml", "circle.yml", ".circle.yml"],
        "GitLab CI" => [".gitlab-ci.yml", ".gitlab-ci.yaml"],
        "Bitbucket Pipelines" => ["bitbucket-pipelines.yml"],
        "Azure Pipelines" => ["azure-pipelines.yml", "azure-pipelines.yaml"],
        "Buildkite" => [".buildkite/pipeline.yml", ".buildkite/pipeline.yaml"],
        "Jenkins" => ["Jenkinsfile"],
        "AppVeyor" => ["appveyor.yml", ".appveyor.yml"]
      }
      detected = configurations.select { |_name, patterns| patterns.any? { |pattern| Dir.glob(pattern).any? { |path| File.file?(path) } } }.keys
      if detected.one?
        ui.say "Detected #{detected.first} configuration."
        return detected.first.downcase
      end

      if detected.empty?
        ui.say "No supported CI configuration detected."
        github_repo = GitRepo.new.exec("remote -v").match?(%r{(?:github\.com[:/])})
        choices = github_repo ? ["GitHub Actions", "Other"] : ["Other", "GitHub Actions"]
      else
        ui.say "Detected multiple CI providers: #{detected.join(', ')}."
        choices = detected + ["Other"]
      end
      ui.ask_with_answers("Which CI would you like to use", choices)
    end

    def show_todo_state
      ui.say "We need to do the following:\n"
      ui.pause 0.6
      ui.say " - [ ] Create a Dangerfile and add a few simple rules."
      if @github_actions
        ui.say " - [ ] Set up a Gemfile for Danger and danger-pr-comment."
        ui.say " - [ ] Set up GitHub Actions to run Danger and post reports.\n\n"
        return
      end
      ui.pause 0.6
      ui.say " - [#{@account_created ? 'x' : ' '}] Create a GitHub account for Danger to use, for messaging."
      ui.pause 0.6
      ui.say " - [ ] Set up an access token for Danger."
      ui.pause 0.6
      ui.say " - [ ] Set up Danger to run on your CI.\n\n"
    end

    def setup_dangerfile
      if File.exist?("Dangerfile")
        ui.say "Keeping your existing Dangerfile."
        return
      end

      content = DangerfileGenerator.create_dangerfile(".", cork)
      content = "danger.import_dangerfile(gem: 'danger-pr-comment')\n\n#{content}" if @github_actions
      File.write("Dangerfile", content)

      ui.header "Step 1: Creating a starter Dangerfile"
      ui.say "I've set up an example Dangerfile for you in this folder.\n"
      ui.pause 1

      ui.say "cat #{Dir.pwd}/Dangerfile\n".blue
      content.lines.each do |l|
        ui.say "  #{l.chomp.green}"
      end
      ui.say ""
      ui.pause 2

      ui.say "There's a collection of small, simple ideas in here, but Danger is about being able to easily"
      ui.say "iterate. The power comes from you having the ability to codify fixes for some of the problems"
      ui.say "that come up in day to day programming. It can be difficult to try and see those from day 1."

      ui.say "\nIf you'd like to investigate the file, and make some changes - I'll wait here,"
      ui.say "press return when you're ready to move on..."
      ui.wait_for_return
    end

    def setup_github_actions
      ui.header "Step 2: Set up GitHub Actions"
      if File.exist?("Gemfile")
        ui.say "Keeping your existing Gemfile. Ensure it includes gem 'danger' and gem 'danger-pr-comment', require: false."
      else
        File.write("Gemfile", "source 'https://rubygems.org'\n\ngem 'danger'\ngem 'danger-pr-comment', require: false\n")
        ui.say "Created a tooling Gemfile for Danger. Your project does not need to use Ruby."
      end
      ui.say "Run bundle install and commit the Gemfile and resulting Gemfile.lock."
      ui.say "Ensure your Dangerfile imports the report exporter before its rules:"
      ui.say "danger.import_dangerfile(gem: 'danger-pr-comment')"

      project_ruby = File.file?(".ruby-version") || (File.file?(".tool-versions") && File.read(".tool-versions").match?(/^\s*ruby\s+/))
      FileUtils.mkdir_p(".github/workflows")
      %w(danger.yml danger-comment.yml).each do |name|
        path = File.join(".github/workflows", name)
        if File.exist?(path)
          ui.say "Keeping #{path}. Merge the setup guide's workflow configuration manually."
        else
          template = File.join(Danger.gem_path, "lib", "assets", name)
          content = File.read(template)
          content = content.sub("      ruby-version: '3.4'\n", "") if project_ruby
          File.write(path, content)
          ui.say "Created #{path}."
        end
      end

      ui.say "GitHub supplies an automatic token; no personal access token, bot account, or secrets: inherit is needed."
      ui.say "Danger runs with read-only permissions on pull_request; a separate workflow posts the report."
      ui.say "Merge both workflows into the default branch to enable comment posting."
      ui.say "Keep the commenting workflow limited to report data; never execute pull request code with write permissions."
      if project_ruby
        ui.say "The generated Danger workflow uses your project's Ruby version configuration."
      else
        ui.say "The generated Danger workflow uses Ruby 3.4 for tooling; adjust ruby-version in .github/workflows/danger.yml if needed."
      end
      ui.link "https://danger.systems/guides/getting_started.html#github-actions-without-a-personal-access-token"
    end

    def setup_github_account
      ui.header "Step 2: Creating a GitHub account"

      ui.say "In order to get the most out of Danger, I'd recommend giving her the ability to post in"
      ui.say "the code-review comment section.\n\n"
      ui.pause 1

      ui.say "IMO, it's best to do this by using the private mode of your browser. Create an account like"
      ui.say "#{@bot_name}, and don't forget a cool robot avatar.\n\n"
      ui.pause 1
      ui.say "Here are great resources for creative commons images of robots:"
      ui.link "https://www.flickr.com/search/?text=robot&license=2%2C3%2C4%2C5%2C6%2C9"
      ui.link "https://www.google.com/search?q=robot&tbs=sur:fmc&tbm=isch&tbo=u&source=univ&sa=X&ved=0ahUKEwjgy8-f95jLAhWI7hoKHV_UD00QsAQIMQ&biw=1265&bih=1359"
      ui.pause 1

      if considered_an_oss_repo?
        ui.say "#{@bot_name} does not need privileged access to your repo or org. This is because Danger will only"
        ui.say "be writing comments, and you do not need special access for that."
      else
        ui.say "#{@bot_name} will need access to your repo. Simply because the code is not available for the public"
        ui.say "to read and comment on."
      end

      ui.say ""
      note_about_clicking_links
      ui.pause 1
      ui.say "\nCool, please press return when you have your account ready (and you've verified the email...)"
      ui.wait_for_return
    end

    def setup_access_token
      ui.header "Step 3: Configuring a GitHub Personal Access Token"

      ui.say "Here's the link, you should open this in the private session where you just created the new GitHub account"
      ui.link "https://github.com/settings/tokens/new"
      ui.pause 1

      @is_open_source = ui.ask_with_answers("For token access rights, I need to know if this is for an Open Source or Closed Source project\n", ["Open", "Closed"])

      if considered_an_oss_repo?
        ui.say "For Open Source projects, I'd recommend giving the token the smallest scope possible."
        ui.say "This means only providing access to #{'public_repo'.yellow} in the token.\n\n"
        ui.pause 1
        ui.say "This token can access public repositories. Keep it in protected CI secrets"
        ui.say "and do not expose it to untrusted pull requests."

        ui.say "\nIt is important that you do not store this token in your repository, as GitHub will automatically revoke it when pushed.\n"
      elsif @is_open_source == "closed"
        ui.say "For Closed Source projects, I'd recommend giving the token access to the whole repo scope."
        ui.say "This means only providing access to #{'repo'.yellow}, and its children in the token.\n\n"
        ui.pause 1
        ui.say "It's worth noting that you #{'should not'.bold.white} re-use this token for OSS repos."
        ui.say "Make a new one for those repos with just #{'public_repo'.yellow}."
        ui.pause 1
        ui.say "Additionally, don't forget to add your new GitHub account as a collaborator to your Closed Source project."
      end

      ui.say "\n👍, please press return when you have your token set up..."
      ui.wait_for_return
    end

    def considered_an_oss_repo?
      @is_open_source == "open"
    end

    def current_repo_slug
      git = GitRepo.new

      author_repo_regexp = %r{(?:[/:])([^/]+/[^/]+)(?:.git)?$}
      last_git_regexp = /.git$/

      matches = git.origins.match(author_repo_regexp)

      matches ? matches[1].gsub(last_git_regexp, "").strip : "[Your/Repo]"
    end

    def setup_danger_ci
      ui.header "Step 4: Add Danger for your CI"

      case @selected_ci
      when "travis ci" then uses_travis
      when "circleci" then uses_circle
      else unsure_ci
      end

      ui.say "\nOK, I'll give you a moment to do this..."
      ui.wait_for_return

      ui.header "Final step: exposing the GitHub token as an environment build variable."
      ui.pause 0.4
      ui.say "Keep tokens secret. Do not expose them to untrusted fork builds."

      case @selected_ci
      when "travis ci" then travis_token
      when "circleci" then circle_token
      else unsure_token
      end

      ui.pause 0.6
      ui.say "This is the last step, I can give you a second..."
      ui.wait_for_return
    end

    def uses_travis
      danger = "bundle exec danger".yellow
      config = YAML.load(File.read(".travis.yml"))
      if config.kind_of?(Hash) && config["script"]
        ui.say "Add #{'- '.yellow}#{danger} as a new step in the #{'script'.yellow} section of your .travis.yml file."
      else
        ui.say "I'd recommend adding #{'before_script: '.yellow}#{danger} to the script section of your .travis.yml file."
      end

      ui.pause 1
      ui.say "You shouldn't use #{'after_success, after_failure, after_script'.red} as they cannot fail your builds."
    end

    def uses_circle
      danger = "- bundle exec danger".yellow
      path = [".circleci/config.yml", ".circleci/config.yaml", "circle.yml", ".circle.yml"].find { |file| File.file?(file) }
      if path.start_with?(".circleci/")
        ui.say "Add a run step for #{'bundle exec danger'.yellow} to a job in #{path}, and include that job in your workflow."
        return
      end
      config = YAML.load(File.read(path))

      if config.kind_of?(Hash) && config["test"]
        if config["test"]["post"]
          ui.say "Add #{danger} as a new step in the #{'test:post:'.yellow} section of your #{path} file."
        else
          ui.say "Add #{danger} as a new step in the #{'test:override:'.yellow} section of your #{path} file."
        end
      else
        ui.say "Add this to the bottom of your #{path} file:"
        ui.say "test:".green
        ui.say "  post:".green
        ui.say "    #{danger}".green
      end
    end

    def unsure_ci
      danger = "bundle exec danger".yellow
      ui.say "For this CI provider, I'll offer generic setup advice."
      ui.say "You want to run #{danger} after your tests have finished running, it should still be during the testing"
      ui.say "process so the build can fail."
    end

    def travis_token
      # https://travis-ci.org/artsy/eigen/settings
      ui.say "In order to add an environment variable, go to:"
      ui.link "https://travis-ci.org/#{current_repo_slug}/settings"
      ui.say "\nThe name is #{'DANGER_GITHUB_API_TOKEN'.yellow} and the value is the GitHub Personal Access Token."
      ui.say 'Keep "Display value in build log" disabled.'
    end

    def circle_token
      # https://circleci.com/gh/artsy/eigen/edit#env-vars
      if considered_an_oss_repo?
        ui.say "Do not pass secrets to fork builds. Restrict token-based Danger runs to trusted branches,"
        ui.say "or separate rule execution from privileged report posting."
      end

      ui.say "In order to expose an environment variable, go to:"
      ui.link "https://circleci.com/gh/#{current_repo_slug}/edit#env-vars"
      ui.say "The name is #{'DANGER_GITHUB_API_TOKEN'.yellow} and the value is the GitHub Personal Access Token."
    end

    def unsure_token
      ui.say "You need to expose a token called #{'DANGER_GITHUB_API_TOKEN'.yellow} and the value is the GitHub Personal Access Token."
      ui.say "Depending on the CI system, this may need to be done on the machine (in the #{'~/.bashprofile'.yellow}) or in a web UI somewhere."
      ui.say "We have a guide for all supported CI systems on danger.systems:"
      ui.link "https://danger.systems/guides/getting_started.html#setting-up-danger-to-run-on-your-ci"
    end

    def note_about_clicking_links
      modifier_key = "ctrl"
      clicks = "clicking"

      modifier_key = "cmd ( ⌘ )" if darwin?
      clicks = "double clicking" if darwin? && !ENV["ITERM_SESSION_ID"]

      ui.say "Note: Holding #{modifier_key} and #{clicks} a link will open it in your browser."
    end

    def info
      ui.header "Useful info"
      ui.say "- One of the best ways to test out new rules locally is via #{'bundle exec danger pr'.yellow}."
      ui.pause 0.6
      ui.say "- You can have Danger output all of her variables to the console via the #{'--verbose'.yellow} option."
      ui.pause 0.6
      ui.say "- You can look at the following Dangerfiles to get some more ideas:"
      ui.pause 0.6
      ui.link "https://github.com/danger/danger/blob/master/Dangerfile"
      ui.link "https://github.com/dblock/ruby-enum/blob/master/Dangerfile"
      ui.pause 1
    end

    def thanks
      ui.say "\n\n🎉"
      ui.pause 0.6

      ui.say "And you're good to go. Danger is a collaboration between Orta Therox, Gem 'Danger' McShane and Felix Krause."
      ui.say "If you like Danger, let others know. If you want to know more, follow #{'@orta'.yellow} and #{'@KrauseFx'.yellow} on Twitter."
      ui.say "If you don't like Danger, help us improve the project! xxx"
    end

    def darwin?
      Gem::Platform.local.os == "darwin"
    end
  end
end
