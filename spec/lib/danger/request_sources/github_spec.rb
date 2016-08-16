# coding: utf-8
require "danger/request_source/request_source"
require "danger/ci_source/circle"
require "danger/ci_source/travis"
require "danger/danger_core/violation"

describe Danger::RequestSources::GitHub do
  describe "the github host" do
    it "sets a default GitHub host" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)
      expect(g.host).to eql("github.com")
    end

    it "allows the GitHub host to be overridden" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }
      g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)
      expect(g.host).to eql("git.club-mateusa.com")
    end

    it "allows the GitHub API host to be overridden" do
      api_endpoint = "https://git.club-mateusa.com/api/v3/"
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_HOST" => api_endpoint }
      Danger::RequestSources::GitHub.new(stub_ci, gh_env)
      expect(Octokit.api_endpoint).to eql(api_endpoint)
    end
  end

  describe "valid server response" do
    before do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      @g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)

      pr_response = JSON.parse(fixture("github_api/pr_response"), symbolize_names: true)
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)

      issue_response = JSON.parse(fixture("github_api/issue_response"), symbolize_names: true)
      allow(@g.client).to receive(:get).with("https://api.github.com/repos/artsy/eigen/issues/800").and_return(issue_response)
    end

    it "sets its pr_json" do
      @g.fetch_details
      expect(@g.pr_json).to be_truthy
    end

    it "sets its issue_json" do
      @g.fetch_details
      expect(@g.issue_json).to be_truthy
    end

    it "sets the ignored violations" do
      @g.fetch_details
      expect(@g.ignored_violations).to eql(["Developer Specific file shouldn't be changed",
                                            "Some warning"])
    end

    describe "#organisation" do
      it "valid value available" do
        @g.fetch_details
        expect(@g.organisation).to eq("artsy")
      end

      it "no valid value available doesn't crash" do
        @g.issue_json = nil
        expect(@g.organisation).to eq(nil)
      end
    end

    describe "#fetch_repository" do
      before do
        @g.fetch_details
      end

      it "works with valid data" do
        issue_response = JSON.parse(fixture("github_api/repo_response"), symbolize_names: true)
        expect(@g.client).to receive(:repo).with("artsy/yolo").and_return(issue_response)

        result = @g.fetch_repository(repository: "yolo")
        expect(result[:url]).to eq("https://api.github.com/repos/Themoji/Danger")
      end

      it "returns nil for no response" do
        expect(@g.client).to receive(:repo).with("artsy/yolo").and_return(nil)

        expect(@g.fetch_repository(repository: "yolo")).to eq(nil)
      end
    end

    describe "#fetch_danger_repo" do
      before do
        @g.fetch_details
      end

      it "tries both 'danger' and 'Danger' as repo, 'Danger' first" do
        issue_response = JSON.parse(fixture("github_api/repo_response"), symbolize_names: true)
        expect(@g.client).to receive(:repo).with("artsy/danger").and_return(nil)
        expect(@g.client).to receive(:repo).with("artsy/Danger").and_return(issue_response)

        result = @g.fetch_danger_repo
        expect(result[:url]).to eq("https://api.github.com/repos/Themoji/Danger")
      end

      it "tries both 'danger' and 'Danger' as repo, 'danger' first" do
        issue_response = JSON.parse(fixture("github_api/repo_response"), symbolize_names: true)
        expect(@g.client).to receive(:repo).with("artsy/danger").and_return(issue_response)

        result = @g.fetch_danger_repo
        expect(result[:url]).to eq("https://api.github.com/repos/Themoji/Danger")
      end
    end

    describe "#danger_repo?" do
      before do
        @g.fetch_details
        @issue_response = JSON.parse(fixture("github_api/repo_response"), symbolize_names: true)
      end

      it "returns true if the repo's name is danger" do
        @issue_response[:name] = "Danger"
        expect(@g.client).to receive(:repo).with("artsy/danger").and_return(@issue_response)
        expect(@g.ci_source).to receive(:repo_slug).and_return("artsy/danger")
        expect(@g.danger_repo?).to eq(true)
      end

      it "returns false if the repo's name is danger (it's eigen)" do
        @issue_response[:name] = "eigen"
        expect(@g.client).to receive(:repo).with("artsy/eigen").and_return(@issue_response)

        expect(@g.danger_repo?).to be_falsey
      end

      it "returns true if the repo is a fork of danger" do
        issue_response = JSON.parse(fixture("github_api/danger_fork_repo"), symbolize_names: true)
        expect(@g.client).to receive(:repo).with("artsy/eigen").and_return(issue_response)

        expect(@g.danger_repo?).to be_truthy
      end
    end

    describe "#file_url" do
      it "returns a valid URL with the minimum parameters" do
        url = @g.file_url(repository: "danger",
                                path: "path/Dangerfile")
        expect(url).to eq("https://raw.githubusercontent.com//danger/master/path/Dangerfile")
      end

      it "returns a valid URL with more parameters" do
        url = @g.file_url(repository: "danger",
                        organisation: "org_yo",
                              branch: "yolo_branch",
                                path: "path/Dangerfile")
        expect(url).to eq("https://raw.githubusercontent.com/org_yo/danger/yolo_branch/path/Dangerfile")
      end
    end

    # TODO: Move to the plugin
    #
    xdescribe "DSL Attributes" do
      it "sets the right commit sha" do
        @g.fetch_details

        expect(@g.pr_json[:base][:sha]).to eql(@g.base_commit)
        expect(@g.pr_json[:head][:sha]).to eql(@g.head_commit)
        expect(@g.pr_json[:base][:ref]).to eql(@g.branch_for_merge)
      end

      it "sets the right labels" do
        @g.fetch_details
        expect(@g.pr_labels).to eql(["D:2", "Maintenance Work"])
      end
    end

    describe "status message" do
      it "Shows a success message when no errors/warnings" do
        message = @g.generate_description(warnings: [], errors: [])
        expect(message).to start_with("All green.")
      end

      it "Shows an error messages when there are errors" do
        message = @g.generate_description(warnings: violations([1, 2, 3]), errors: [])
        expect(message).to eq("⚠ 3 Warnings. Don't worry, everything is fixable.")
      end

      it "Shows an error message when errors and warnings" do
        message = @g.generate_description(warnings: violations([1, 2]), errors: violations([1, 2, 3]))
        expect(message).to eq("⚠ 3 Errors. 2 Warnings. Don't worry, everything is fixable.")
      end

      it "Deals with singualars in messages when errors and warnings" do
        message = @g.generate_description(warnings: violations([1]), errors: violations([1]))
        expect(message).to eq("⚠ 1 Error. 1 Warning. Don't worry, everything is fixable.")
      end
    end

    describe "commit status update" do
      before do
        stub_request(:post, "https://git.club-mateusa.com/api/v3/repos/artsy/eigen/statuses/").to_return status: 200
      end

      it "fails when no head commit is set" do
        @g.pr_json = { base: { sha: "" }, head: { sha: "" } }
        expect do
          @g.submit_pull_request_status!
        end.to raise_error("Couldn't find a commit to update its status".red)
      end
    end

    describe "issue creation" do
      before do
        @g.pr_json = { base: { sha: "" }, head: { sha: "" } }
        allow(@g).to receive(:submit_pull_request_status!).and_return(true)
      end

      it "creates a comment if no danger comments exist" do
        comments = []
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations(["hi"]), errors: [], messages: [])
        expect(@g.client).to receive(:add_comment).with("artsy/eigen", "800", body).and_return({})

        @g.update_pull_request!(warnings: violations(["hi"]), errors: [], messages: [])
      end

      it "updates the issue if no danger comments exist" do
        comments = [{ body: "generated_by_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations(["hi"]), errors: [], messages: [])
        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", body).and_return({})

        @g.update_pull_request!(warnings: violations(["hi"]), errors: [], messages: [])
      end

      it "updates the issue if no danger comments exist and a custom danger_id is provided" do
        comments = [{ body: "generated_by_another_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations(["hi"]), errors: [], messages: [], danger_id: "another_danger")
        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", body).and_return({})

        @g.update_pull_request!(warnings: violations(["hi"]), errors: [], messages: [], danger_id: "another_danger")
      end

      it "deletes existing comments if danger doesnt need to say anything" do
        comments = [{ body: "generated_by_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end

      it "deletes existing comments if danger doesnt need to say anything and a custom danger_id is provided" do
        comments = [{ body: "generated_by_another_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [], danger_id: "another_danger")
      end

      it "updates the comment if danger doesnt need to say anything but there are sticky violations" do
        comments = [{ body: "generated_by_danger", id: "12" }]
        allow(@g).to receive(:parse_comment).and_return({ errors: ["an error"] })
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", any_args).and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end
    end
  end
end
