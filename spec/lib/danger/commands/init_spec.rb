# frozen_string_literal: true

require "danger/commands/init"
require "tmpdir"

RSpec.describe Danger::Init do
  describe "#run" do
    let(:command) { Danger::Init.new CLAide::ARGV.new([]) }
    let(:ui) { double("interviewer", say: nil, pause: nil, header: nil, link: nil, wait_for_return: nil) }

    around do |example|
      Dir.mktmpdir do |directory|
        Dir.chdir(directory) { example.run }
      end
    end

    before do
      command.ui = ui
      allow_any_instance_of(Danger::GitRepo).to receive(:exec).with("remote -v").and_return("origin git@github.com:author/repo.git (fetch)")
      allow(ui).to receive(:ask_with_answers).with("Which CI would you like to use", ["GitHub Actions", "Other"]).and_return("github actions")
    end

    it "offers GitHub Actions first and generates fork-compatible workflows without token prompts" do
      expect(command).not_to receive(:setup_github_account)
      expect(command).not_to receive(:setup_access_token)
      expect(command).not_to receive(:setup_danger_ci)

      command.run

      expect(File.read("Dangerfile")).to start_with("danger.import_dangerfile(gem: 'danger-pr-comment')")
      run_workflow = YAML.safe_load(File.read(".github/workflows/danger.yml"))
      comment_workflow = YAML.safe_load(File.read(".github/workflows/danger-comment.yml"))
      expect(run_workflow.fetch("permissions")).to eq("contents" => "read", "pull-requests" => "read")
      expect(run_workflow.fetch("jobs").fetch("danger").fetch("uses")).to include("/danger-run.yml@")
      expect(comment_workflow.fetch("on", comment_workflow[true]).fetch("workflow_run").fetch("workflows")).to eq(["Danger"])
      expect(comment_workflow.fetch("permissions")).to include("pull-requests" => "write")
      expect(comment_workflow.fetch("jobs").fetch("comment").fetch("uses")).to include("/danger-comment.yml@")
      expect(File.read("Gemfile")).to eq("source 'https://rubygems.org'\n\ngem 'danger'\ngem 'danger-pr-comment', require: false\n")
      expect(run_workflow.fetch("jobs").fetch("danger").fetch("with").fetch("ruby-version")).to eq("3.4")
      expect(run_workflow.fetch("jobs").fetch("danger").fetch("with").fetch("danger-args")).to eq("pr ${{ github.event.pull_request.html_url }} --fail-on-errors=true")
      expect(ui).to have_received(:say).with(/Merge both workflows into the default branch/)
    end

    it "preserves existing Dangerfiles and workflows and explains manual integration" do
      File.write("Dangerfile", "message('existing')")
      File.write("Gemfile", "gem 'existing'")
      FileUtils.mkdir_p(".github/workflows")
      File.write(".github/workflows/danger.yml", "existing run workflow")
      File.write(".github/workflows/danger-comment.yml", "existing comment workflow")

      command.run

      expect(File.read("Dangerfile")).to eq("message('existing')")
      expect(File.read("Gemfile")).to eq("gem 'existing'")
      expect(ui).to have_received(:say).with(/Keeping your existing Gemfile/)
      expect(File.read(".github/workflows/danger.yml")).to eq("existing run workflow")
      expect(File.read(".github/workflows/danger-comment.yml")).to eq("existing comment workflow")
      expect(ui).to have_received(:say).with("Ensure your Dangerfile imports the report exporter before its rules:")
      expect(ui).to have_received(:say).with("Keeping .github/workflows/danger.yml. Merge the setup guide's workflow configuration manually.")
    end

    it "retains the other CI setup without generating GitHub Actions workflows" do
      allow(ui).to receive(:ask_with_answers).and_return("other")
      expect(command).to receive(:setup_github_account)
      expect(command).to receive(:setup_access_token)
      expect(command).to receive(:setup_danger_ci)

      command.run

      expect(File.read("Dangerfile")).not_to include("danger-pr-comment")
      expect(Dir.exist?(".github/workflows")).to be false
    end

    it "detects GitHub Actions from YAML files, not an empty workflows directory" do
      FileUtils.mkdir_p(".github/workflows")
      expect(command.select_ci).to eq("github actions")
      expect(ui).to have_received(:ask_with_answers).once

      File.write(".github/workflows/test.yaml", "name: Tests")
      expect(command.select_ci).to eq("github actions")
      expect(ui).to have_received(:ask_with_answers).once
      expect(ui).to have_received(:say).with("Detected GitHub Actions configuration.")
    end

    {
      ".travis.yml" => "travis ci",
      ".circleci/config.yml" => "circleci",
      ".circle.yml" => "circleci",
      ".gitlab-ci.yml" => "gitlab ci",
      "bitbucket-pipelines.yml" => "bitbucket pipelines",
      "azure-pipelines.yml" => "azure pipelines",
      ".buildkite/pipeline.yml" => "buildkite",
      "Jenkinsfile" => "jenkins",
      "appveyor.yml" => "appveyor"
    }.each do |path, provider|
      it "prefers detected #{provider} over the GitHub fallback" do
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "")
        expect(ui).not_to receive(:ask_with_answers)
        expect(command.select_ci).to eq(provider)
      end
    end

    it "asks which detected provider to use and configures only that provider" do
      FileUtils.mkdir_p(".github/workflows")
      File.write(".github/workflows/test.yml", "")
      File.write(".travis.yml", "")
      File.write("circle.yml", "")
      expect(ui).to receive(:ask_with_answers).with("Which CI would you like to use", ["GitHub Actions", "Travis CI", "CircleCI", "Other"]).and_return("circleci")
      expect(command).to receive(:setup_github_account)
      expect(command).to receive(:setup_access_token)
      expect(command).to receive(:uses_circle)
      expect(command).to receive(:circle_token)
      expect(command).not_to receive(:uses_travis)
      expect(command).not_to receive(:travis_token)

      command.run

      expect(File.exist?(".github/workflows/danger.yml")).to be false
    end

    it "offers Other first when neither CI configuration nor a GitHub remote exists" do
      allow_any_instance_of(Danger::GitRepo).to receive(:exec).with("remote -v").and_return("origin git@gitlab.com:author/repo.git (fetch)")
      expect(ui).to receive(:ask_with_answers).with("Which CI would you like to use", ["Other", "GitHub Actions"]).and_return("other")
      expect(command.select_ci).to eq("other")
    end

    it "gives modern CircleCI instructions for .circleci/config.yml" do
      FileUtils.mkdir_p(".circleci")
      File.write(".circleci/config.yml", "version: 2.1")
      command.uses_circle
      expect(ui).to have_received(:say).with(/include that job in your workflow/)
    end

    [".ruby-version", ".tool-versions"].each do |path|
      it "uses existing Ruby configuration from #{path}" do
        File.write(path, path == ".ruby-version" ? "3.3.5\n" : "ruby 3.3.5\nnodejs 22.0.0\n")
        command.run
        workflow = YAML.safe_load(File.read(".github/workflows/danger.yml"))
        expect(workflow.fetch("jobs").fetch("danger").fetch("with")).not_to have_key("ruby-version")
      end
    end

    it "provides a tooling Ruby when .tool-versions only configures other languages" do
      File.write(".tool-versions", "nodejs 22.0.0\n")
      command.run
      workflow = YAML.safe_load(File.read(".github/workflows/danger.yml"))
      expect(workflow.fetch("jobs").fetch("danger").fetch("with").fetch("ruby-version")).to eq("3.4")
    end
  end

  describe "#current_repo_slug" do
    let(:command) { Danger::Init.new CLAide::ARGV.new([]) }

    context "with git url" do
      it "returns correct results" do
        url = "git@github.com:author/repo.git"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "author/repo"
      end
    end

    context "with github pages url" do
      it "returns correct results" do
        url = "https://github.com/author/repo.github.io.git"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "author/repo.github.io"
      end
    end

    context "with other url" do
      it "returns [Your/Repo]" do
        url = "http://example.com"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "[Your/Repo]"
      end
    end
  end
end
