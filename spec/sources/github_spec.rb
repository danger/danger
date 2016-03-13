# coding: utf-8
require 'danger/request_sources/github'
require 'danger/ci_source/circle'
require 'danger/ci_source/travis'

def stub_ci
  env = { "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800" }
  Danger::CISource::CircleCI.new(env)
end

def fixture(file)
  File.read("spec/fixtures/#{file}.json")
end

describe Danger::GitHub do
  describe "the github host" do
    it 'sets a default GitHub host' do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      g = Danger::GitHub.new(stub_ci, gh_env)
      expect(g.github_host).to eql("github.com")
    end

    it 'allows the GitHub host to be overridden' do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }
      g = Danger::GitHub.new(stub_ci, gh_env)
      expect(g.github_host).to eql("git.club-mateusa.com")
    end

    it 'allows the GitHub API host to be overridden' do
      api_endpoint = "https://git.club-mateusa.com/api/v3/"
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_HOST" => api_endpoint }
      g = Danger::GitHub.new(stub_ci, gh_env)
      expect(Octokit.api_endpoint).to eql(api_endpoint)
    end
  end

  describe "valid server response" do
    before do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      @g = Danger::GitHub.new(stub_ci, gh_env)

      pr_response = JSON.parse(fixture("pr_response"), symbolize_names: true)
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)

      issue_response = JSON.parse(fixture("issue_response"), symbolize_names: true)
      allow(@g.client).to receive(:get).with("https://api.github.com/repos/artsy/eigen/issues/800").and_return(issue_response)
    end

    it 'sets its pr_json' do
      @g.fetch_details
      expect(@g.pr_json).to be_truthy
    end

    it 'sets its issue_json' do
      @g.fetch_details
      expect(@g.issue_json).to be_truthy
    end

    it 'sets the right commit sha' do
      @g.fetch_details

      expect(@g.pr_json[:base][:sha]).to eql(@g.base_commit)
      expect(@g.pr_json[:head][:sha]).to eql(@g.head_commit)
      expect(@g.pr_json[:base][:ref]).to eql(@g.branch_for_merge)
    end

    it 'sets the right labels' do
      @g.fetch_details
      expect(@g.pr_labels).to eql(["D:2", "Maintenance Work"])
    end

    it 'sets the ignored violations' do
      @g.fetch_details
      expect(@g.ignored_violations).to eql(["Developer Specific file shouldn't be changed",
                                            "Some warning"])
    end

    describe "#generate_comment" do
      before do
        @date = Time.now.strftime("%Y-%m-%d")
      end

      it "shows the base/head commit" do
        env = {
          "CIRCLE_BUILD_NUM" => "true",
          "CI_PULL_REQUEST" => "https://github.com/artsy/eigen/pull/800",
          "CIRCLE_COMPARE_URL" => "https://github.com/artsy/eigen/compare/759adcbd0d8f...13c4dc8bb61d"
        }
        source = Danger::CISource::CircleCI.new(env)
        @g.base_commit = "2525245"
        @g.head_commit = "90528352"
        @g.ci_source = source
        result = @g.generate_comment(warnings: [], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          "<palign=\"right\"data-meta=\"generated_by_danger\"data-base-commit=\"2525245\"data-head-commit=\"90528352\">Generatedby:no_entry_sign:<ahref=\"https://github.com/danger/danger/\">danger</a></p>"
        )
      end

      it "no warnings, no errors, no messages" do
        result = @g.generate_comment(warnings: [], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          "<palign=\"right\"data-meta=\"generated_by_danger\"data-base-commit=\"\"data-head-commit=\"\">Generatedby:no_entry_sign:<ahref=\"https://github.com/danger/danger/\">danger</a></p>"
        )
      end

      it "some warnings, no errors" do
        result = @g.generate_comment(warnings: ["my warning", "second warning"], errors: [], messages: [])
        # rubocop:disable Metrics/LineLength
        expect(result.gsub(/\s+/, "")).to eq(
          "<table><thead><tr><thwidth=\"50\"></th><thwidth=\"100%\">2Warnings</th></tr></thead><tbody><tr><td>:warning:</td><td>mywarning</td></tr><tr><td>:warning:</td><td>secondwarning</td></tr></tbody></table><palign=\"right\"data-meta=\"generated_by_danger\"data-base-commit=\"\"data-head-commit=\"\">Generatedby:no_entry_sign:<ahref=\"https://github.com/danger/danger/\">danger</a></p>"
        )
        # rubocop:enable Metrics/LineLength
      end

      it "some warnings with markdown, no errors" do
        warnings = ["a markdown [link to danger](https://github.com/danger/danger)", "second **warning**"]
        result = @g.generate_comment(warnings: warnings, errors: [], messages: [])
        # rubocop:disable Metrics/LineLength
        expect(result.gsub(/\s+/, "")).to eq(
          "<table><thead><tr><thwidth=\"50\"></th><thwidth=\"100%\">2Warnings</th></tr></thead><tbody><tr><td>:warning:</td><td>amarkdown<ahref=\"https://github.com/danger/danger\">linktodanger</a></td></tr><tr><td>:warning:</td><td>second<strong>warning</strong></td></tr></tbody></table><palign=\"right\"data-meta=\"generated_by_danger\"data-base-commit=\"\"data-head-commit=\"\">Generatedby:no_entry_sign:<ahref=\"https://github.com/danger/danger/\">danger</a></p>"
        )
        # rubocop:enable Metrics/LineLength
      end

      it "some warnings, some errors" do
        result = @g.generate_comment(warnings: ["my warning"], errors: ["some error"], messages: [])
        # rubocop:disable Metrics/LineLength
        expect(result.gsub(/\s+/, "")).to eq(
          "<table><thead><tr><thwidth=\"50\"></th><thwidth=\"100%\">1Error</th></tr></thead><tbody><tr><td>:no_entry_sign:</td><td>someerror</td></tr></tbody></table><table><thead><tr><thwidth=\"50\"></th><thwidth=\"100%\">1Warning</th></tr></thead><tbody><tr><td>:warning:</td><td>mywarning</td></tr></tbody></table><palign=\"right\"data-meta=\"generated_by_danger\"data-base-commit=\"\"data-head-commit=\"\">Generatedby:no_entry_sign:<ahref=\"https://github.com/danger/danger/\">danger</a></p>"
        )
        # rubocop:enable Metrics/LineLength
      end

      it "needs to include generated_by_danger" do
        result = @g.generate_comment(warnings: ["my warning"], errors: ["some error"], messages: [])
        expect(result.gsub(/\s+/, "")).to include("generated_by_danger")
      end
    end

    describe "status message" do
      it "Shows a success message when no errors/warnings" do
        message = @g.generate_github_description(warnings: [], errors: [])
        expect(message).to start_with("All green.")
      end

      it "Shows an error messages when there are errors" do
        message = @g.generate_github_description(warnings: [1, 2, 3], errors: [])
        expect(message).to eq("⚠ 3 Warnings. Don't worry, everything is fixable.")
      end

      it "Shows an error message when errors and warnings" do
        message = @g.generate_github_description(warnings: [1, 2], errors: [1, 2, 3])
        expect(message).to eq("⚠ 3 Errors. 2 Warnings. Don't worry, everything is fixable.")
      end

      it "Deals with singualars in messages when errors and warnings" do
        message = @g.generate_github_description(warnings: [1], errors: [1])
        expect(message).to eq("⚠ 1 Error. 1 Warning. Don't worry, everything is fixable.")
      end
    end

    describe "issue creation" do
      it "creates an issue if no danger comments exist" do
        issues = []
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(issues)

        body = @g.generate_comment(warnings: ["hi"], errors: [], messages: [])
        expect(@g.client).to receive(:add_comment).with("artsy/eigen", "800", body).and_return({})

        @g.update_pull_request!(warnings: ["hi"], errors: [], messages: [])
      end

      it "updates the issue if no danger comments exist" do
        issues = [{ body: "generated_by_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(issues)

        body = @g.generate_comment(warnings: ["hi"], errors: [], messages: [])
        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", body).and_return({})

        @g.update_pull_request!(warnings: ["hi"], errors: [], messages: [])
      end

      it "deletes existing issues danger doesnt need to say anything" do
        issues = [{ body: "generated_by_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(issues)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end
    end
  end
end
