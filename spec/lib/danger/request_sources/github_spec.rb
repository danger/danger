# coding: utf-8

require "danger/request_sources/github/github"
require "danger/ci_source/circle"
require "danger/ci_source/travis"
require "danger/danger_core/messages/violation"

RSpec.describe Danger::RequestSources::GitHub, host: :github do
  describe "the github host" do
    it "sets a default GitHub host" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }

      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).host

      expect(result).to eq("github.com")
    end

    it "allows the GitHub host to be overridden" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }
      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).host

      expect(result).to eq("git.club-mateusa.com")
    end

    describe "#api_url" do
      it "allows the GitHub API host to be overridden with `DANGER_GITHUB_API_BASE_URL`" do
        api_endpoint = "https://git.club-mateusa.com/api/v3/"
        gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_BASE_URL" => api_endpoint }

        result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).api_url

        expect(result).to eq api_endpoint
      end

      it "allows the GitHub API host to be overridden with `DANGER_GITHUB_API_HOST` for backwards compatibility" do
        api_endpoint = "https://git.club-mateusa.com/api/v4/"
        gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_API_HOST" => api_endpoint }

        result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).api_url

        expect(result).to eq api_endpoint
      end
    end
  end

  describe "ssl verification" do
    it "sets ssl verification environment variable to false" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com", "DANGER_OCTOKIT_VERIFY_SSL" => "false" }

      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).verify_ssl
      expect(result).to be_falsey
    end

    it "sets ssl verification environment variable to true" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com", "DANGER_OCTOKIT_VERIFY_SSL" => "true" }

      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).verify_ssl
      expect(result).to be_truthy
    end

    it "sets ssl verification environment variable to wrong input" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com", "DANGER_OCTOKIT_VERIFY_SSL" => "wronginput" }

      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).verify_ssl
      expect(result).to be_truthy
    end

    it "unsets ssl verification environment variable" do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi", "DANGER_GITHUB_HOST" => "git.club-mateusa.com" }

      result = Danger::RequestSources::GitHub.new(stub_ci, gh_env).verify_ssl
      expect(result).to be_truthy
    end
  end

  describe "valid server response" do
    before do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      @g = Danger::RequestSources::GitHub.new(stub_ci, gh_env)

      pr_response = JSON.parse(fixture("github_api/pr_response"))
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(pr_response)

      issue_response = JSON.parse(fixture("github_api/issue_response"))
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
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return({ "message" => "Moved Permanently" })

      expect do
        @g.fetch_details
      end.to raise_error("Repo moved or renamed, make sure to update the git remote".red)
    end

    it "sets the ignored violations" do
      @g.fetch_details

      expect(@g.ignored_violations).to eq(
        [
          "Developer Specific file shouldn't be changed",
          "Some warning"
        ]
      )
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
      before do
        contents_response = JSON.parse(fixture("github_api/contents_response"))
        allow(@g.client).to receive(:contents).with("artsy/danger", path: "Dangerfile", ref: nil).and_return(contents_response)
        allow(@g.client).to receive(:contents).with("artsy/danger", path: "path/Dangerfile", ref: "master").and_return(contents_response)
        allow(@g.client).to receive(:contents).with("teapot/danger", path: "Dangerfile", ref: nil).and_raise(Octokit::NotFound)
      end

      it "returns a valid URL with the minimum parameters" do
        url = @g.file_url(organisation: "artsy", repository: "danger", path: "Dangerfile")
        expect(url).to eq("https://raw.githubusercontent.com/artsy/danger/master/path/Dangerfile")
      end

      it "returns a valid URL with more parameters" do
        url = @g.file_url(repository: "danger", organisation: "artsy", branch: "master", path: "path/Dangerfile")
        expect(url).to eq("https://raw.githubusercontent.com/artsy/danger/master/path/Dangerfile")
      end

      it "returns a valid fallback URL" do
        url = @g.file_url(repository: "danger", organisation: "teapot", path: "Dangerfile")
        expect(url).to eq("https://raw.githubusercontent.com/teapot/danger/master/Dangerfile")
      end
    end

    describe "review" do
      context "when already asked for review" do
        before do
          allow(@g.client).to receive(:pull_request_reviews).with("artsy/eigen", "800").and_return([])
          @created_review = @g.review
        end

        it "returns the same review" do
          expect(@g.review).to eq(@created_review)
        end
      end

      context "when ask for review first time" do
        context "when there are no danger review for PR" do
          before do
            allow(@g.client).to receive(:pull_request_reviews).with("artsy/eigen", "800").and_return([])
          end

          it "returns a newly created review" do
            @review = @g.review
            expect(@review.review_json).to be_nil
          end
        end

        context "when there are danger review for PR" do
          before do
            pr_reviews_response = JSON.parse(fixture("github_api/pr_reviews_response"))
            allow(@g.client).to receive(:pull_request_reviews).with("artsy/eigen", "800").and_return(pr_reviews_response)
          end

          it "returns the last review from danger" do
            @review = @g.review
            expect(@review.review_json).to_not be_nil
            expect(@review.id).to eq(16_237_194)
          end
        end
      end

      context "when running against github enterprise which doesn't support reviews" do
        it "returns an unsupported review instance" do
          allow(@g.client).to receive(:pull_request_reviews).with("artsy/eigen", "800").and_raise(Octokit::NotFound)

          review = @g.review
          expect(review).to respond_to(
            :id, :body, :status, :review_json, :start, :submit, :message, :warn,
            :fail, :markdown
          )
        end
      end
    end

    describe "status message" do
      it "Shows a success message when no errors/warnings" do
        message = @g.generate_description(warnings: [], errors: [])
        expect(message).to start_with("All green.")
      end

      it "Shows an error messages when there are errors" do
        message = @g.generate_description(warnings: violations_factory([1, 2, 3]), errors: [])
        expect(message).to eq("⚠️ 3 Warnings. Don't worry, everything is fixable.")
      end

      it "Shows an error message when errors and warnings" do
        message = @g.generate_description(warnings: violations_factory([1, 2]), errors: violations_factory([1, 2, 3]))
        expect(message).to eq("⚠️ 3 Errors. 2 Warnings. Don't worry, everything is fixable.")
      end

      it "Deals with singualars in messages when errors and warnings" do
        message = @g.generate_description(warnings: violations_factory([1]), errors: violations_factory([1]))
        expect(message).to eq("⚠️ 1 Error. 1 Warning. Don't worry, everything is fixable.")
      end
    end

    describe "commit status update" do
      before do
        stub_request(:post, "https://git.club-mateusa.com/api/v3/repos/artsy/eigen/statuses/").to_return status: 200
      end

      it "fails when no head commit is set" do
        @g.pr_json = { "base" => { "sha" => "" }, "head" => { "sha" => "" } }
        expect do
          @g.submit_pull_request_status!
        end.to raise_error("Couldn't find a commit to update its status".red)
      end

      it "uses danger_id as context of status" do
        options = hash_including(context: "danger/special_context")
        expect(@g.client).to receive(:create_status).with(any_args, options).and_return({})

        @g.pr_json = { "head" => { "sha" => "pr_commit_ref" } }
        @g.submit_pull_request_status!(danger_id: "special_context")
      end

      it "aborts when access to setting the status was denied but there were errors" do
        stub_request(:post, "https://api.github.com/repos/artsy/eigen/statuses/pr_commit_ref").to_return(status: 404)

        @g.pr_json = { "head" => { "sha" => "pr_commit_ref" }, "base" => { "repo" => { "private" => true } } }

        expect do
          @g.submit_pull_request_status!(errors: violations_factory(["error"]))
        end.to raise_error.and output(/Danger has failed this build/).to_stderr
      end

      it "warns when access to setting the status was denied but no errors were reported" do
        stub_request(:post, "https://api.github.com/repos/artsy/eigen/statuses/pr_commit_ref").to_return(status: 404)

        @g.pr_json = { "head" => { "sha" => "pr_commit_ref" }, "base" => { "repo" => { "private" => true } } }

        expect do
          @g.submit_pull_request_status!(warnings: violations_factory(["error"]))
        end.to output(/warning.*not have write access/im).to_stdout
      end
    end

    describe "issue creation" do
      before do
        @g.pr_json = { "base" => { "sha" => "" }, "head" => { "sha" => "" } }
        allow(@g).to receive(:submit_pull_request_status!).and_return(true)
      end

      it "creates a comment if no danger comments exist" do
        comments = []
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations_factory(["hi"]), errors: [], messages: [])
        expect(@g.client).to receive(:add_comment).with("artsy/eigen", "800", body).and_return({})

        @g.update_pull_request!(warnings: violations_factory(["hi"]), errors: [], messages: [])
      end

      it "updates the issue if no danger comments exist" do
        comments = [{ "body" => '"generated_by_danger"', "id" => "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations_factory(["hi"]), errors: [], messages: [])
        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", body).and_return({})

        @g.update_pull_request!(warnings: violations_factory(["hi"]), errors: [], messages: [])
      end

      it "creates a new comment instead of updating the issue if --new-comment is provided" do
        comments = [{ "body" => '"generated_by_danger"', "id" => "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations_factory(["hi"]), errors: [], messages: [])
        expect(@g.client).to receive(:add_comment).with("artsy/eigen", "800", body).and_return({})

        @g.update_pull_request!(warnings: violations_factory(["hi"]), errors: [], messages: [], new_comment: true)
      end

      it "updates the issue if no danger comments exist and a custom danger_id is provided" do
        comments = [{ "body" => '"generated_by_another_danger"', "id" => "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        body = @g.generate_comment(warnings: violations_factory(["hi"]), errors: [], messages: [], danger_id: "another_danger")
        expect(@g.client).to receive(:update_comment).with("artsy/eigen", "12", body).and_return({})

        @g.update_pull_request!(warnings: violations_factory(["hi"]), errors: [], messages: [], danger_id: "another_danger")
      end

      it "deletes existing comments if danger doesnt need to say anything" do
        comments = [{ "body" => '"generated_by_danger"', "id" => "12" }]
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return(comments)

        allow(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", "12").and_return({})
        @g.update_pull_request!(warnings: [], errors: [], messages: [])
      end

      it "deletes existing comments if danger doesnt need to say anything and a custom danger_id is provided" do
        comments = [{ "body" => '"generated_by_another_danger"', "id" => "12" }]
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
        issues = JSON.parse(fixture("github_api/inline_comments"))
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

        expect(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 4)
        @g.update_pull_request!(warnings: [], errors: [], messages: [v])
      end

      it "adds main comment when inline out of range" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return([])

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 10)
        body = @g.generate_comment(warnings: [], errors: [], messages: [v])

        expect(@g.client).not_to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 10)
        expect(@g.client).to receive(:add_comment).with("artsy/eigen", "800", body).and_return({})

        @g.update_pull_request!(warnings: [], errors: [], messages: [v])
      end

      it "ingores out of range inline comments when in dismiss mode" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])

        expect(@g.client).not_to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 10)
        expect(@g.client).not_to receive(:add_comment).with("artsy/eigen", "800", anything)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 10)
        @g.dismiss_out_of_range_messages = true
        @g.update_pull_request!(warnings: [], errors: [], messages: [v])
      end

      it "ingores out of range inline comments when in dismiss mode per kind" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])

        expect(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        v = Danger::Violation.new("Sure thing", true, "CHANGELOG.md", 4)
        m = Danger::Markdown.new("Sure thing", "CHANGELOG.md", 4)
        @g.dismiss_out_of_range_messages = {
          warning: false,
          error: false,
          message: false,
          markdown: true
        }
        @g.update_pull_request!(warnings: [], errors: [], messages: [v], markdowns: [m])
      end

      it "crosses out sticky comments" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])

        expect(@g.client).to receive(:create_pull_request_comment).with("artsy/eigen", "800", anything, "561827e46167077b5e53515b4b7349b8ae04610b", "CHANGELOG.md", 4)

        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_1).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", inline_issue_id_2).and_return({})
        expect(@g.client).to receive(:delete_comment).with("artsy/eigen", main_issue_id).and_return({})

        m = Danger::Markdown.new("Sure thing", "CHANGELOG.md", 4)
        @g.update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [m])
      end

      it "removes inline comments if they are not included" do
        issues = [{ "body" => "'generated_by_another_danger'", "id" => "12" }]
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

      it "keeps initial messages order" do
        allow(@g.client).to receive(:pull_request_comments).with("artsy/eigen", "800").and_return([])
        allow(@g.client).to receive(:issue_comments).with("artsy/eigen", "800").and_return([])
        allow(@g.client).to receive(:add_comment).and_return({})
        allow(@g).to receive(:submit_pull_request_status!).and_return(true)
        allow(@g.client).to receive(:create_pull_request_comment).and_return({})
        allow(@g.client).to receive(:delete_comment).and_return(true)
        allow(@g.client).to receive(:delete_comment).and_return(true)

        messages = [
          Danger::Violation.new("1", false, nil, nil),
          Danger::Violation.new("2", false, nil, nil),
          Danger::Violation.new("3", false, nil, nil),
          Danger::Violation.new("4", false, nil, nil),
          Danger::Violation.new("5", false, nil, nil),
          Danger::Violation.new("6", false, nil, nil),
          Danger::Violation.new("7", false, nil, nil),
          Danger::Violation.new("8", false, nil, nil),
          Danger::Violation.new("9", false, nil, nil),
          Danger::Violation.new("10", false, nil, nil)
        ]

        expect(@g).to receive(:generate_comment).with(
          template: "github",
          danger_id: "danger",
          previous_violations: {},
          warnings: [],
          errors: [],
          messages: messages,
          markdowns: []
        )

        @g.update_pull_request!(messages: messages)
      end
    end

    describe "branch setup" do
      it "setups the danger branches" do
        @g.fetch_details
        expect(@g.scm).to receive(:exec)
          .with("rev-parse --quiet --verify 704dc55988c6996f69b6873c2424be7d1de67bbe^{commit}")
          .and_return("345e74fabb2fecea93091e8925b1a7a208b48ba6")

        expect(@g.scm).to receive(:exec)
          .with("branch danger_base 704dc55988c6996f69b6873c2424be7d1de67bbe")

        expect(@g.scm).to receive(:exec)
          .with("rev-parse --quiet --verify 561827e46167077b5e53515b4b7349b8ae04610b^{commit}")
          .and_return("561827e46167077b5e53515b4b7349b8ae04610b")

        expect(@g.scm).to receive(:exec)
          .with("branch danger_head 561827e46167077b5e53515b4b7349b8ae04610b")

        @g.setup_danger_branches
      end

      it "fetches when the branches are not in the local store" do
        # not in history
        expect(@g.scm).to receive(:exec).
          with("rev-parse --quiet --verify 704dc55988c6996f69b6873c2424be7d1de67bbe^{commit}").
          and_return("")

        [20, 74, 222, 625].each do |depth|
          # fetch it
          expect(@g.scm).to receive(:exec).with("fetch --depth=#{depth} --prune origin +refs/heads/master:refs/remotes/origin/master")
          # still not in history
          expect(@g.scm).to receive(:exec).
            with("rev-parse --quiet --verify 704dc55988c6996f69b6873c2424be7d1de67bbe^{commit}").
            and_return("")
        end

        # fetch it
        expect(@g.scm).to receive(:exec).with("fetch --depth 1000000")
        # still not in history
        expect(@g.scm).to receive(:exec).
          with("rev-parse --quiet --verify 704dc55988c6996f69b6873c2424be7d1de67bbe^{commit}").
          and_return("")

        expect do
          @g.fetch_details
          @g.setup_danger_branches
        end.to raise_error(RuntimeError, /Commit (\w+|\b[0-9a-f]{5,40}\b) doesn't exist/)
      end
    end
  end

  describe "#find_position_in_diff" do
    subject do
      github.find_position_in_diff(diff_lines, message, kind)
    end

    let(:diff_lines) do
      <<-DIFF.each_line.to_a
diff --git a/#{file_path} b/#{file_path}
index 0000000..0000001 100644
--- a/#{file_path}
+++ b/#{file_path}
@@ -1 +1,2 @@
-foo
+bar
+baz
      DIFF
    end

    let(:file_path) do
      "dummy"
    end

    let(:github) do
      described_class.new(stub_ci, "DANGER_GITHUB_API_TOKEN" => "hi")
    end

    let(:kind) do
      :dummy
    end

    let(:message) do
      double(
        file: file_path,
        line: 1,
      )
    end

    context "when the lines count for the original file is omitted" do
      it "returns correct position" do
        is_expected.to eq(2)
      end
    end

    context "when diff contain `No newline` annotation before added lines" do
      let(:diff_lines) do
        <<-DIFF.each_line.to_a
diff --git a/#{file_path} b/#{file_path}
index 0000000..0000001 100644
--- a/#{file_path}
+++ b/#{file_path}
@@ -1 +1,3 @@
-foo
\\ No newline at end of file
+foo
+bar
+baz
        DIFF
      end

      it "returns correct position" do
        is_expected.to eq(3)
      end
    end
  end
end
