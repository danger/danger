# coding: utf-8
require "danger/request_sources/github"
require "danger/ci_source/circle"
require "danger/ci_source/travis"
require "danger/danger_core/messages/violation"

describe Danger::RequestSources::GitHub, host: :github do
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

    describe "#api_url" do
      it "allows the GitHub API host to be overridden with `DANGER_GITHUB_API_BASE_URL`" do
        api_endpoint = "https://git.club-mateusa.com/api/v3/"
        gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_BASE_URL" => api_endpoint }
        Danger::RequestSources::GitHub.new(stub_ci, gh_env)
        expect(Octokit.api_endpoint).to eql(api_endpoint)
      end

      it "allows the GitHub API host to be overridden with `DANGER_GITHUB_API_HOST` for backwards compatibility" do
        api_endpoint = "https://git.club-mateusa.com/api/v4/"
        gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_HOST" => api_endpoint }
        Danger::RequestSources::GitHub.new(stub_ci, gh_env)
        expect(Octokit.api_endpoint).to eql(api_endpoint)
      end
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

    it "raises an exception when the repo was moved from the git remote" do
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return({ message: "Moved Permanently" })

      expect do
        @g.fetch_details
      end.to raise_error("Repo moved or renamed, make sure to update the git remote".red)
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

        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end

      it "deletes existing comments if danger doesnt need to say anything and a custom danger_id is provided" do
        comments = [{ body: "generated_by_another_danger", id: "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})

        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id)
        @g.update_pull_request!(warnings: [], errors: [], messages: [], danger_id: "another_danger")
      end

      # it "updates the comment if danger doesnt need to say anything but there are sticky violations" do
      #   comments = [{ body: "generated_by_danger", id: "12" }]
      #   allow(@g).to receive(:parse_comment).and_return({ errors: ["an error"] })
      #   allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

      #   expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", any_args).and_return({})
      #   @g.update_pull_request!(warnings: [], errors: [], messages: [])
      # end
    end

    describe "#parse_message_from_row" do
      it "handles pulling out links that include the file / line when in the main Danger comment" do
        body = '<a href="https://github.com/artsy/eigen/blob/8e5d0bab431839a7046b2f7d5cd5ccb91677fe23/CHANGELOG.md#L1">CHANGELOG.md#L1</a> - Testing inline docs'

        v = @g.parse_message_from_row(body)
        expect(v.file).to eq("CHANGELOG.md")
        expect(v.line).to eq(1)
        expect(v.message).to include("- Testing inline docs")
      end

      it "handles pulling out file info from an inline Danger comment" do
        body = '<span data-href="https://github.com/artsy/eigen/blob/8e5d0bab431839a7046b2f7d5cd5ccb91677fe23/CHANGELOG.md#L1"/>Testing inline docs'
        v = @g.parse_message_from_row(body)
        expect(v.file).to eq("CHANGELOG.md")
        expect(v.line).to eq(1)
        expect(v.message).to include("Testing inline docs")
      end
    end

    let(:main_issue_id) { 76_535_362 }
    let(:inline_issue_id_1) { 76_537_315 }
    let(:inline_issue_id_2) { 76_537_316 }

    describe "inline issues" do
      before do
        issues = JSON.parse(fixture("github_api/inline_comments"), symbolize_names: true)
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(issues)

        diff = diff_fixture("github_api/inline_comments_pr_diff")
        allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800", { accept: "application/vnd.github.v3.diff" }).and_return(diff)

        @g.fetch_details
        allow(@g).to receive(:submit_pull_request_status!)
      end

      it "deletes all inline comments if there are no violations at all" do
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id)
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1)
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2)

        allow(@g).to receive(:submit_pull_request_status!)

        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end

      it "adds new comments inline" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])

        allow(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 4)
        @g.update_pull_request!(warnings: [], errors: [], messages: [v])
      end

      it "crosses out sticky comments" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])

        allow(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        m = Danger::Markdown.new("Sure thing", "CHANGELOG.md", 4)
        @g.update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [m])
      end

      it "removes inline comments if they are not included" do
        issues = [{ body: "generated_by_another_danger", id: "12" }]
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return(issues)

        allow(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        # Main
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id)
        # Inline Issues
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1)
        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2)

        allow(@g).to receive(:submit_pull_request_status!)

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 4)
        @g.update_pull_request!(warnings: [], errors: [], messages: [v])
      end
    end
  end
end
