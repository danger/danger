# coding: utf-8

require "erb"

require "danger/request_sources/gitlab"

RSpec.describe Danger::RequestSources::GitLab, host: :gitlab do
  let(:env) { stub_env.merge("CI_MERGE_REQUEST_IID" => 1) }
  let(:subject) { stub_request_source(env) }

  describe "the GitLab host" do
    it "sets the default GitLab host" do
      expect(subject.host).to eq("gitlab.com")
    end

    it "allows the GitLab host to be overidden" do
      env["DANGER_GITLAB_HOST"] = "gitlab.example.com"

      expect(subject.host).to eq("gitlab.example.com")
    end
  end

  describe "the GitLab API endpoint" do
    it "sets the default GitLab API endpoint" do
      expect(subject.endpoint).to eq("https://gitlab.com/api/v4")
    end

    it "allows the GitLab API endpoint to be overidden with `DANGER_GITLAB_API_BASE_URL`" do
      env["DANGER_GITLAB_API_BASE_URL"] = "https://gitlab.example.com/api/v3"

      expect(subject.endpoint).to eq("https://gitlab.example.com/api/v3")
    end
  end

  describe "the GitLab API client" do
    it "sets the provide token" do
      env["DANGER_GITLAB_API_TOKEN"] = "token"

      expect(subject.client.private_token).to eq("token")
    end

    it "set the default API endpoint" do
      expect(subject.client.endpoint).to eq("https://gitlab.com/api/v4")
    end

    it "respects overriding the API endpoint" do
      env["DANGER_GITLAB_API_BASE_URL"] = "https://gitlab.example.com/api/v3"

      expect(subject.client.endpoint).to eq("https://gitlab.example.com/api/v3")
    end
  end

  describe "validation" do
    it "validates as an API source" do
      expect(subject.validates_as_api_source?).to be_truthy
    end

    it "does no validate as an API source when the API token is empty" do
      env["DANGER_GITLAB_API_TOKEN"] = ""

      result = stub_request_source(env).validates_as_api_source?

      expect(result).to be_falsey
    end

    it "does no validate as an API source when there is no API token" do
      env.delete("DANGER_GITLAB_API_TOKEN")

      result = stub_request_source(env).validates_as_api_source?

      expect(result).to be_falsey
    end

    it "does not validate as CI when there is a port number included in host" do
      env["DANGER_GITLAB_HOST"] = "gitlab.example.com:2020"

      expect { stub_request_source(env).validates_as_ci? }.to raise_error("Port number included in `DANGER_GITLAB_HOST`, this will fail with GitLab CI Runners")
    end

    it "does validate as CI when there is no port number included in host" do
      env["DANGER_GITLAB_HOST"] = "gitlab.example.com"

      git_mock = Danger::GitRepo.new
      g = stub_request_source(env)
      g.scm = git_mock

      allow(git_mock).to receive(:exec).with("remote show origin -n").and_return("Fetch URL: git@gitlab.example.com:artsy/eigen.git")

      result = g.validates_as_ci?

      expect(result).to be_truthy
    end
  end

  describe "scm" do
    it "Sets up the scm" do
      expect(subject.scm).to be_kind_of(Danger::GitRepo)
    end
  end

  describe "valid server response" do
    before do
      stub_merge_request(
        "merge_request_1_response",
        "k0nserv%2Fdanger-test",
        1
      )
      @comments_stub = stub_merge_request_comments(
        "merge_request_1_comments_response",
        "k0nserv%2Fdanger-test",
        1
      )
    end

    it "determines the correct base_commit" do
      subject.fetch_details

      expect(subject.base_commit).to eq("0e4db308b6579f7cc733e5a354e026b272e1c076")
    end

    it "setups the danger branches" do
      subject.fetch_details

      expect(subject.scm).to receive(:exec)
        .with("rev-parse --quiet --verify 0e4db308b6579f7cc733e5a354e026b272e1c076^{commit}")
        .and_return("0e4db308b6579f7cc733e5a354e026b272e1c076")

      expect(subject.scm).to receive(:exec)
        .with("branch danger_base 0e4db308b6579f7cc733e5a354e026b272e1c076")

      expect(subject.scm).to receive(:exec)
        .with("rev-parse --quiet --verify 04e58de1fa97502d7e28c1394d471bb8fb1fc4a8^{commit}")
        .and_return("04e58de1fa97502d7e28c1394d471bb8fb1fc4a8")

      expect(subject.scm).to receive(:exec)
        .with("branch danger_head 04e58de1fa97502d7e28c1394d471bb8fb1fc4a8")

      subject.setup_danger_branches
    end

    it "set its mr_json" do
      subject.fetch_details

      expect(subject.mr_json).to be_truthy
    end

    it "sets its ignored_violations_from_pr" do
      subject.fetch_details

      expect(subject.ignored_violations).to eq(
        [
          "Developer specific files shouldn't be changed",
          "Testing"
        ]
      )
    end

    describe "#supports_inline_comments" do

      before do
        skip "gitlab gem older than 4.6.0" if Gem.loaded_specs["gitlab"].version < Gem::Version.new("4.6.0")
      end

      it "is false on verions before 10.8" do
        stub_version("10.6.4")

        expect(subject.supports_inline_comments).to be_falsey
      end

      it "is true on version 10.8" do
        stub_version("10.8.0")

        expect(subject.supports_inline_comments).to be_truthy
      end

      it "is true on versions after 10.8" do
        stub_version("11.7.0")

        expect(subject.supports_inline_comments).to be_truthy
      end

    end

    describe "#update_pull_request!" do

      before do
        @version_stub = stub_version("11.7.0")
        stub_merge_request_discussions(
          "merge_request_1_discussions_empty_response",
          "k0nserv%2Fdanger-test",
          1
        )
      end

      it "checks if the server supports inline comments" do
        skip "gitlab gem older than 4.6.0" if Gem.loaded_specs["gitlab"].version < Gem::Version.new("4.6.0")
        subject.update_pull_request!(
          warnings: [],
          errors: [],
          messages: []
        )
        expect(@version_stub).to have_been_made
      end

      it "creates a new comment when there is not one already" do
        body = subject.generate_comment(
          warnings: violations_factory(["Test warning"]),
          errors: violations_factory(["Test error"]),
          messages: violations_factory(["Test message"]),
          template: "gitlab"
        )
        stub_request(:post, "https://gitlab.com/api/v4/projects/k0nserv%2Fdanger-test/merge_requests/1/notes").with(
          body: "body=#{ERB::Util.url_encode(body)}",
          headers: expected_headers
        ).to_return(status: 200, body: "", headers: {})
        subject.update_pull_request!(
          warnings: violations_factory(["Test warning"]),
          errors: violations_factory(["Test error"]),
          messages: violations_factory(["Test message"])
        )
      end

      context "doesn't support inline comments" do

        before do
          stub_version("10.7.0")
        end

        context "existing comment" do
          before do
            remove_request_stub(@comments_stub)

            @comments_stub = stub_merge_request_comments(
              "merge_request_1_comments_existing_danger_comment_response",
              "k0nserv%2Fdanger-test",
              1
            )
          end

          it "updates the existing comment instead of creating a new one" do
            allow(subject).to receive(:random_compliment).and_return("random compliment")
            body = subject.generate_comment(
              warnings: violations_factory(["New Warning"]),
              errors: [],
              messages: [],
              previous_violations: {
                warning: [],
                error: violations_factory(["Test error"]),
                message: []
              },
              template: "gitlab"
            )
            stub_request(:put, "https://gitlab.com/api/v4/projects/k0nserv%2Fdanger-test/merge_requests/1/notes/13471894").with(
              body: {
                body: body
              },
              headers: expected_headers
            ).to_return(status: 200, body: "", headers: {})

            subject.update_pull_request!(
              warnings: violations_factory(["New Warning"]),
              errors: [],
              messages: []
            )
          end

          it "creates a new comment instead of updating the existing one if --new-comment is provided" do
            body = subject.generate_comment(
              warnings: violations_factory(["Test warning"]),
              errors: violations_factory(["Test error"]),
              messages: violations_factory(["Test message"]),
              template: "gitlab"
            )
            stub_request(:post, "https://gitlab.com/api/v4/projects/k0nserv%2Fdanger-test/merge_requests/1/notes").with(
              body: {
                body: body
              },
              headers: expected_headers
            ).to_return(status: 200, body: "", headers: {})
            subject.update_pull_request!(
              warnings: violations_factory(["Test warning"]),
              errors: violations_factory(["Test error"]),
              messages: violations_factory(["Test message"]),
              new_comment: true
            )
          end
        end

        context "existing comment with no sticky messages" do
          before do
            remove_request_stub(@comments_stub)

            @comments_stub = stub_merge_request_comments(
              "merge_request_1_comments_no_stickies_response",
              "k0nserv%2Fdanger-test",
              1
            )
          end

          it "removes the previous danger comment if there are no new messages" do
            stub_request(:delete, "https://gitlab.com/api/v4/projects/k0nserv%2Fdanger-test/merge_requests/1/notes/13471894").with(
              headers: expected_headers
            )

            subject.update_pull_request!(
              warnings: [],
              errors: [],
              messages: []
            )
          end
        end

      end

      context "supports inline comments" do
        before do
          stub_version("11.7.0")
          skip "gitlab gem older than 4.6.0" if Gem.loaded_specs["gitlab"].version < Gem::Version.new("4.6.0")
        end

        it "adds new comments inline" do
          stub_merge_request_changes(
            "merge_request_1_changes_response",
            "k0nserv\%2Fdanger-test",
            1
          )

          expect(subject.client).to receive(:create_merge_request_discussion)
          allow(subject.client).to receive(:delete_merge_request_comment)

          subject.fetch_details

          v = Danger::Violation.new("Sure thing", true, "a", 4)
          subject.update_pull_request!(warnings: [], errors: [], messages: [v])
        end

        it "edits existing inline comment instead of creating a new one if file/line matches" do
          stub_merge_request_discussions(
            "merge_request_1_discussions_response",
            "k0nserv%2Fdanger-test",
            1
          )
          stub_merge_request_changes(
            "merge_request_1_changes_response",
            "k0nserv\%2Fdanger-test",
            1
          )

          v = Danger::Violation.new("Updated danger comment", true, "a", 1)
          body = subject.generate_inline_comment_body("warning", subject.process_markdown(v, true), danger_id: "danger", template: "gitlab")

          expect(subject.client).to receive(:update_merge_request_discussion_note).with("k0nserv/danger-test", 1, "f5fd1ab23556baa6683b4b3b36ec4455f8b500f4", 141485123, body: body)
          allow(subject.client).to receive(:update_merge_request_discussion_note)
          allow(subject.client).to receive(:delete_merge_request_comment)

          subject.fetch_details

          subject.update_pull_request!(warnings: [v], errors: [], messages: [])
        end

        it "deletes non-sticky comments if no violations are present" do
          stub_merge_request_discussions(
            "merge_request_1_discussions_response",
            "k0nserv%2Fdanger-test",
            1
          )

          # Global comment gets updated as its sticky
          allow(subject.client).to receive(:edit_merge_request_note)

          # Inline comment
          expect(subject.client).to receive(:delete_merge_request_comment).with("k0nserv/danger-test", 1, 141485123)

          subject.update_pull_request!(warnings: [], errors: [], messages: [])
        end

        it "deletes inline comments if those are no longer relevant" do
          stub_merge_request_discussions(
            "merge_request_1_discussions_response",
            "k0nserv%2Fdanger-test",
            1
          )

          expect(subject.client).to receive(:edit_merge_request_note)
          allow(subject.client).to receive(:update_merge_request_discussion_note)
          expect(subject.client).to receive(:delete_merge_request_comment).with("k0nserv/danger-test", 1, 141485123)

          v = Danger::Violation.new("Test error", true)
          subject.update_pull_request!(warnings: [], errors: [v], messages: [])
        end

        it "skips inline comments for files that are not part of the diff" do
          stub_merge_request_discussions(
            "merge_request_1_discussions_response",
            "k0nserv%2Fdanger-test",
            1
          )
          stub_merge_request_changes(
            "merge_request_1_changes_response",
            "k0nserv\%2Fdanger-test",
            1
          )

          allow(subject.client).to receive(:update_merge_request_discussion_note)
          allow(subject.client).to receive(:delete_merge_request_comment)
          allow(subject.client).to receive(:edit_merge_request_note)

          v = Danger::Violation.new("Error on not-on-diff file", true, "not-on-diff", 1)

          subject.fetch_details

          subject.update_pull_request!(warnings: [v], errors: [], messages: [])
        end

        it "doesn't crash if an inline comment fails to publish" do
          stub_merge_request_discussions(
            "merge_request_1_discussions_empty_response",
            "k0nserv%2Fdanger-test",
            1
          )
          stub_merge_request_changes(
            "merge_request_1_changes_response",
            "k0nserv\%2Fdanger-test",
            1
          )

          url = "https://gitlab.com/api/v4/projects/k0nserv%2Fdanger-test/merge_requests/1/discussions"
          WebMock.stub_request(:post, url).to_return(status: [400, "Note {:line_code=>[\"can't be blank\", \"must be a valid line code\"]}"])

          v = Danger::Violation.new("Some error", true, "a", 1)

          allow(subject.client).to receive(:create_merge_request_note)

          subject.fetch_details
          subject.update_pull_request!(warnings: [v], errors: [], messages: [])
        end

      end
    end

    describe "#file_url" do
      it "returns a valid URL with the minimum parameters" do
        url = subject.file_url(repository: 1, path: "Dangerfile")
        expect(url).to eq("https://gitlab.com/api/v4/projects/1/repository/files/Dangerfile/raw?ref=master&private_token=a86e56d46ac78b")
      end

      it "returns a valid URL with more parameters" do
        url = subject.file_url(repository: 1, organisation: "artsy", branch: "develop", path: "path/Dangerfile")
        expect(url).to eq("https://gitlab.com/api/v4/projects/1/repository/files/path/Dangerfile/raw?ref=develop&private_token=a86e56d46ac78b")
      end

      it "returns a valid fallback URL" do
        url = subject.file_url(repository: 1, organisation: "teapot", path: "Dangerfile")
        expect(url).to eq("https://gitlab.com/api/v4/projects/1/repository/files/Dangerfile/raw?ref=master&private_token=a86e56d46ac78b")
      end
    end

    describe "#find_old_position_in_diff" do
      let(:new_path) do
        "dummy"
      end

      let(:old_path) do
        "dummy"
      end

      let(:new_file) do
        false
      end

      let(:renamed_file) do
        false
      end

      let(:deleted_file) do
        false
      end

      let(:diff_lines) do
        ""
      end

      let(:changes) do
        [{
           "new_path" => new_path,
           "old_path" => old_path,
           "diff" => diff_lines,
           "new_file" => new_file,
           "renamed_file" => renamed_file,
           "deleted_file" => deleted_file
         }]
      end

      context "new file" do
        let(:diff_lines) do
          <<-DIFF
@@ -0,0 +1,3 @@
+foo
+bar
+baz
          DIFF
        end

        let(:new_file) do
          true
        end

        it "returns path only" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 1))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to be_nil
        end
      end

      context "slightly modified file" do
        let(:diff_lines) do
          <<-DIFF
@@ -1 +1,2 @@
-foo
+bar
+baz
          DIFF
        end

        it "returns path only" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 1))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to be_nil
        end
      end

      context "heavily modified files" do
        let(:diff_lines) do
          <<-DIFF
@@ -2,7 +2,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
@@ -21,7 +22,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
          DIFF
        end

        it "returns path only when message line is new" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 5))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to be_nil
        end

        it "returns path and correct line when message line isn't new" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 3))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to eq(3)
        end

        it "returns path and correct line when the line is before diffs" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 1))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to eq(1)
        end

        it "returns path and correct line when the line is between diffs" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 15))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to eq(14)
        end

        it "returns path and correct line when the line is after diffs" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 35))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to eq(33)
        end
      end

      context "deleted file" do
        let(:diff_lines) do
          <<-DIFF
@@ -1,3 +0,0 @@
-foo
-bar
-baz
          DIFF
        end

        let(:deleted_file) do
          true
        end

        it "returns nil" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 1))
          expect(position).to be_nil
        end
      end

      context "renamed only file" do

        let(:renamed_file) do
          true
        end

        let(:new_path) do
          "new_dummy"
        end

        it "returns nil" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 1))
          expect(position).to be_nil
        end
      end

      context "renamed and modified file" do
        let(:diff_lines) do
          <<-DIFF
@@ -1 +1,2 @@
@@ -2,7 +2,8 @@
 a
 a
 a
-foo
+bar
+baz
 a
 a
 a
          DIFF
        end

        let(:renamed_file) do
          true
        end

        let(:new_path) do
          "dummy_new"
        end

        it "returns old path only when message line is new" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 5))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to be_nil
        end

        it "returns old path and correct line when message line isn't new" do
          position = subject.find_old_position_in_diff(changes, double(file: new_path, line: 3))
          expect(position[:path]).to eq(old_path)
          expect(position[:line]).to eq(3)
        end
      end

      context "unchanged file" do
        let(:diff_lines) do
          <<-DIFF
@@ -0,0 +1,3 @@
+foo
+bar
+baz
          DIFF
        end

        it "returns nil" do
          position = subject.find_old_position_in_diff(changes, double(file: "dummy_unchanged", line: 5))
          expect(position).to be_nil
        end
      end
    end
  end
end
