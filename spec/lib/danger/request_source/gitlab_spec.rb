# coding: utf-8
require "erb"

require "danger/request_source/request_source"

describe Danger::RequestSources::GitLab, host: :gitlab do
  let(:env) { stub_env }
  let(:g) { Danger::RequestSources::GitLab.new(stub_ci, env) }

  describe "the GitLab host" do
    it "sets the default GitLab host" do
      expect(g.host).to eql("gitlab.com")
    end

    it "allows the GitLab host to be overidden" do
      env["DANGER_GITLAB_HOST"] = "gitlab.example.com"
      expect(g.host).to eql("gitlab.example.com")
    end
  end

  describe "the GitLab API endpoint" do
    it "sets the default GitLab API endpoint" do
      expect(g.endpoint).to eql("https://gitlab.com/api/v3")
    end

    it "allows the GitLab API endpoint to be overidden with `DANGER_GITLAB_API_BASE_URL`" do
      env["DANGER_GITLAB_API_BASE_URL"] = "https://gitlab.example.com/api/v3"
      expect(g.endpoint).to eql("https://gitlab.example.com/api/v3")
    end
  end

  describe "the GitLab API client" do
    it "sets the provide token" do
      env["DANGER_GITLAB_API_TOKEN"] = "token"
      expect(g.client.private_token).to eql("token")
    end

    it "set the default API endpoint" do
      expect(g.client.endpoint).to eql("https://gitlab.com/api/v3")
    end

    it "respects overriding the API endpoint" do
      env["DANGER_GITLAB_API_BASE_URL"] = "https://gitlab.example.com/api/v3"
      expect(g.client.endpoint).to eql("https://gitlab.example.com/api/v3")
    end
  end

  describe "validation" do
    it "validates as an API source" do
      expect(g.validates_as_api_source?).to be_truthy
    end

    it "does no validate as an API source when the API token is empty" do
      env = stub_env
      env["DANGER_GITLAB_API_TOKEN"] = ""
      g = Danger::RequestSources::GitLab.new(stub_ci, env)

      expect(g.validates_as_api_source?).to be_falsey
    end

    it "does no validate as an API source when there is no API token" do
      env = stub_env
      env.delete("DANGER_GITLAB_API_TOKEN")
      g = Danger::RequestSources::GitLab.new(stub_ci, env)

      expect(g.validates_as_api_source?).to be_falsey
    end
  end

  describe "scm" do
    it "Sets up the scm" do
      expect(g.scm).to be_kind_of(Danger::GitRepo)
    end
  end

  describe "valid server response" do
    before do
      stub_merge_request(
        "merge_request_593728_response",
        "k0nserv/danger-test",
        593_728
      )
      stub_merge_request_commits(
        "merge_request_593728_commits_response",
        "k0nserv/danger-test",
        593_728
      )
      @comments_stub = stub_merge_request_comments(
        "merge_request_593728_comments_response",
        "k0nserv/danger-test",
        593_728
      )
    end

    it "determines the correct base_commit" do
      g.fetch_details
      expect(g.scm).to receive(:exec)
        .with("rev-parse adae7c389e1d261da744565fdd5fdebf16e559d1^1")
        .and_return("0e4db308b6579f7cc733e5a354e026b272e1c076")

      expect(g.base_commit).to eq("0e4db308b6579f7cc733e5a354e026b272e1c076")
    end

    it "setups the danger branches" do
      g.fetch_details
      expect(g.scm).to receive(:head_commit).and_return("345e74fabb2fecea93091e8925b1a7a208b48ba6")
      expect(g).to receive(:base_commit).and_return("0e4db308b6579f7cc733e5a354e026b272e1c076")

      expect(g.scm).to receive(:exec)
        .with("branch danger_head 345e74fabb2fecea93091e8925b1a7a208b48ba6")
      expect(g.scm).to receive(:exec)
        .with("branch danger_base 0e4db308b6579f7cc733e5a354e026b272e1c076")

      g.setup_danger_branches
    end

    it "set its mr_json" do
      g.fetch_details
      expect(g.mr_json).to be_truthy
    end

    it "sets its commits_json" do
      g.fetch_details
      expect(g.commits_json).to be_truthy
    end

    it "sets its ignored_violations_from_pr" do
      g.fetch_details
      expect(g.ignored_violations).to eq(
        [
          "Developer specific files shouldn't be changed",
          "Testing"
        ]
      )
    end

    describe "#update_pull_request!" do
      it "creates a new comment when there is not one already" do
        body = g.generate_comment(
          warnings: violations(["Test warning"]),
          errors: violations(["Test error"]),
          messages: violations(["Test message"]),
          template: "gitlab"
        )
        stub_request(:post, "https://gitlab.com/api/v3/projects/k0nserv%2Fdanger-test/merge_requests/593728/notes").with(
          body: "body=#{ERB::Util.url_encode(body)}",
          headers: expected_headers
        ).to_return(status: 200, body: "", headers: {})
        g.update_pull_request!(
          warnings: violations(["Test warning"]),
          errors: violations(["Test error"]),
          messages: violations(["Test message"])
        )
      end

      context "existing comment" do
        before do
          remove_request_stub(@comments_stub)

          @comments_stub = stub_merge_request_comments(
            "merge_request_593728_comments_existing_danger_comment_response",
            "k0nserv/danger-test",
            593_728
          )
        end

        it "updates the existing comment instead of creating a new one" do
          allow(g).to receive(:random_compliment).and_return("random compliment")
          body = g.generate_comment(
            warnings: violations(["New Warning"]),
            errors: [],
            messages: [],
            previous_violations: {
              warning: [],
              error: violations(["Test error"]),
              message: []
            },
            template: "gitlab"
          )

          stub_request(:put, "https://gitlab.com/api/v3/projects/k0nserv%2Fdanger-test/merge_requests/593728/notes/13471894").with(
            body: "body=#{ERB::Util.url_encode(body)}",
            headers: expected_headers
          ).to_return(status: 200, body: "", headers: {})
          g.update_pull_request!(
            warnings: violations(["New Warning"]),
            errors: [],
            messages: []
          )
        end
      end

      context "existing comment with no sticky messages" do
        before do
          remove_request_stub(@comments_stub)

          @comments_stub = stub_merge_request_comments(
            "merge_request_593728_comments_no_stickies_response",
            "k0nserv/danger-test",
            593_728
          )
        end

        it "removes the previous danger comment if there are no new messages" do
          stub_request(:delete, "https://gitlab.com/api/v3/projects/k0nserv%2Fdanger-test/merge_requests/593728/notes/13471894").with(
            headers: expected_headers
          )

          g.update_pull_request!(
            warnings: [],
            errors: [],
            messages: []
          )
        end
      end
    end
  end
end
