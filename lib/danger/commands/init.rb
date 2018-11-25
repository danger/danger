require "danger/commands/init_helpers/interviewer"
require "danger/danger_core/dangerfile_generator"
require "danger/ci_source/local_git_repo"
require "yaml"

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
      @bot_name = File.basename(Dir.getwd).split(".").first.capitalize + "Bot"
      super
      @ui = Interviewer.new(cork)
      ui.no_delay = argv.flag?("impatient", false)
      ui.no_waiting = argv.flag?("mousey", false)
    end

    def run
      ui.say "\nOK, thanks #{ENV['LOGNAME']}, have a seat and we'll get you started.\n".yellow
      ui.pause 1

      show_todo_state
      ui.pause 1.4

      setup_dangerfile
      setup_github_account
      setup_access_token
      setup_danger_ci

      info
      thanks
    end

    def show_todo_state
      ui.say "We need to do the following:\n"
      ui.pause 0.6
      ui.say " - [ ] Create a Dangerfile and add a few simple rules."
      ui.pause 0.6
      ui.say " - [#{@account_created ? 'x' : ' '}] Create a GitHub account for Danger to use, for messaging."
      ui.pause 0.6
      ui.say " - [ ] Set up an access token for Danger."
      ui.pause 0.6
      ui.say " - [ ] Set up Danger to run on your CI.\n\n"
    end

    def setup_dangerfile
      content = DangerfileGenerator.create_dangerfile(".", cork)
      File.write("Dangerfile", content)

      ui.header "Step 1: Creating a starter Dangerfile"
      ui.say "I've set up an example Dangerfile for you in this folder.\n"
      ui.pause 1

      ui.say "cat #{Dir.pwd}/Dangerfile\n".blue
      content.lines.each do |l|
        ui.say "  " + l.chomp.green
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
        ui.say "This means only providing access to " + "public_repo".yellow + " in the token.\n\n"
        ui.pause 1
        ui.say "This token limits Danger's abilities to just writing comments on OSS projects. I recommend"
        ui.say "this because the token can quite easily be extracted from the environment via pull requests."

        ui.say "\nIt is important that you do not store this token in your repository, as GitHub will automatically revoke it when pushed.\n"
      elsif @is_open_source == "closed"
        ui.say "For Closed Source projects, I'd recommend giving the token access to the whole repo scope."
        ui.say "This means only providing access to " + "repo".yellow + ", and its children in the token.\n\n"
        ui.pause 1
        ui.say "It's worth noting that you " + "should not".bold.white + " re-use this token for OSS repos."
        ui.say "Make a new one for those repos with just " + "public_repo".yellow + "."
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

      author_repo_regexp = %r{(?:[\/:])([^\/]+\/[^\/]+)(?:.git)?$}
      last_git_regexp = /.git$/

      matches = git.origins.match(author_repo_regexp)

      matches ? matches[1].gsub(last_git_regexp, "").strip : "[Your/Repo]"
    end

    def setup_danger_ci
      ui.header "Step 4: Add Danger for your CI"

      uses_travis if File.exist? ".travis.yml"
      uses_circle if File.exist? "circle.yml"
      unsure_ci unless File.exist?(".travis.yml") || File.exist?(".circle.yml")

      ui.say "\nOK, I'll give you a moment to do this..."
      ui.wait_for_return

      ui.header "Final step: exposing the GitHub token as an environment build variable."
      ui.pause 0.4
      if considered_an_oss_repo?
        ui.say "As you have an Open Source repo, this token should be considered public, otherwise you cannot"
        ui.say "run Danger on pull requests from forks, limiting its use.\n"
        ui.pause 1
      end

      travis_token if File.exist? ".travis.yml"
      circle_token if File.exist? "circle.yml"
      unsure_token unless File.exist?(".travis.yml") || File.exist?(".circle.yml")

      ui.pause 0.6
      ui.say "This is the last step, I can give you a second..."
      ui.wait_for_return
    end

    def uses_travis
      danger = "bundle exec danger".yellow
      config = YAML.load(File.read(".travis.yml"))
      if config.kind_of?(Hash) && config["script"]
        ui.say "Add " + "- ".yellow + danger + " as a new step in the " + "script".yellow + " section of your .travis.yml file."
      else
        ui.say "I'd recommend adding " + "before_script: ".yellow + danger + " to the script section of your .travis.yml file."
      end

      ui.pause 1
      ui.say "You shouldn't use " + "after_success, after_failure, after_script".red + " as they cannot fail your builds."
    end

    def uses_circle
      danger = "- bundle exec danger".yellow
      config = YAML.load(File.read("circle.yml"))

      if config.kind_of?(Hash) && config["test"]
        if config["test"]["post"]
          ui.say "Add " + danger + " as a new step in the " + "test:post:".yellow + " section of your circle.yml file."
        else
          ui.say "Add " + danger + " as a new step in the " + "test:override:".yellow + " section of your circle.yml file."
        end
      else
        ui.say "Add this to the bottom of your circle.yml file:"
        ui.say "test:".green
        ui.say "  post:".green
        ui.say "    #{danger}".green
      end
    end

    def unsure_ci
      danger = "bundle exec danger".yellow
      ui.say "As I'm not sure what CI you want to run Danger on based on the files in your repo, I'll just offer some generic"
      ui.say "advice. You want to run " + danger + " after your tests have finished running, it should still be during the testing"
      ui.say "process so the build can fail."
    end

    def travis_token
      # https://travis-ci.org/artsy/eigen/settings
      ui.say "In order to add an environment variable, go to:"
      ui.link "https://travis-ci.org/#{current_repo_slug}/settings"
      ui.say "\nThe name is " + "DANGER_GITHUB_API_TOKEN".yellow + " and the value is the GitHub Personal Access Token."
      if @is_open_source
        ui.say 'Make sure to have "Display value in build log" enabled.'
      end
    end

    def circle_token
      # https://circleci.com/gh/artsy/eigen/edit#env-vars
      if considered_an_oss_repo?
        ui.say "Before we start, it's important to be up-front. CircleCI only really has one option to support running Danger"
        ui.say "for forks on OSS repos. It is quite a drastic option, and I want to let you know the best place to understand"
        ui.say "the ramifications of turning on a setting I'm about to advise.\n"
        ui.link "https://circleci.com/docs/fork-pr-builds"
        ui.say "TLDR: If you have anything other than Danger config settings in CircleCI, then you should not turn on the setting."
        ui.say "I'll give you a minute to read it..."
        ui.wait_for_return

        ui.say "On danger/danger we turn on " + "Permissive building of fork pull requests".yellow + " this exposes the token to Danger"
        ui.say "You can find this setting at:"
        ui.link "https://circleci.com/gh/#{current_repo_slug}/edit#advanced-settings\n"
        ui.say "I'll hold..."
        ui.wait_for_return
      end

      ui.say "In order to expose an environment variable, go to:"
      ui.link "https://circleci.com/gh/#{current_repo_slug}/edit#env-vars"
      ui.say "The name is " + "DANGER_GITHUB_API_TOKEN".yellow + " and the value is the GitHub Personal Access Token."
    end

    def unsure_token
      ui.say "You need to expose a token called " + "DANGER_GITHUB_API_TOKEN".yellow + " and the value is the GitHub Personal Access Token."
      ui.say "Depending on the CI system, this may need to be done on the machine (in the " + "~/.bashprofile".yellow + ") or in a web UI somewhere."
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
      ui.say "- One of the best ways to test out new rules locally is via " + "bundle exec danger pr".yellow + "."
      ui.pause 0.6
      ui.say "- You can have Danger output all of her variables to the console via the " + "--verbose".yellow + " option."
      ui.pause 0.6
      ui.say "- You can look at the following Dangerfiles to get some more ideas:"
      ui.pause 0.6
      ui.link "https://github.com/danger/danger/blob/master/Dangerfile"
      ui.link "https://github.com/artsy/eigen/blob/master/Dangerfile"
      ui.pause 1
    end

    def thanks
      ui.say "\n\n🎉"
      ui.pause 0.6

      ui.say "And you're good to go. Danger is a collaboration between Orta Therox, Gem 'Danger' McShane and Felix Krause."
      ui.say "If you like Danger, let others know. If you want to know more, follow " + "@orta".yellow + " and " + "@KrauseFx".yellow + " on Twitter."
      ui.say "If you don't like Danger, help us improve the project! xxx"
    end

    def darwin?
      Gem::Platform.local.os == "darwin"
    end
  end
end
