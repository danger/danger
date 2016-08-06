# coding: utf-8
require "erb"
require "danger/request_source/request_source"

describe Danger::RequestSources::GitLab do
  let(:env) { stub_env(:gitlab) }
  let(:g) { Danger::RequestSources::GitLab.new(stub_ci(:gitlab), env) }

  describe "the GitLab host" do
    it "sets the default GitLab host" do
      expect(g.host).to eql("gitlab.com")
    end

    it "allows the GitLab host to be overidden" do
      env["DANGER_GITLAB_HOST"] = "gitlab.example.com"
    end
  end

  describe "the GitLab API endpoint" do
    it "sets the default GitLab API endpoint" do
      expect(g.endpoint).to eql("https://gitlab.com/api/v3")
    end

    it "allows the GitLab API endpoint to be overidden" do
      env["DANGER_GITLAB_API_ENDPOINT"] = "https://gitlab.example.com/api/v3"
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
      env["DANGER_GITLAB_API_ENDPOINT"] = "https://gitlab.example.com/api/v3"
      expect(g.client.endpoint).to eql("https://gitlab.example.com/api/v3")
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
      stub_merge_request_comments(
        "merge_request_593728_comments_response",
        "k0nserv/danger-test",
        593_728
      )
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
        stub_request(:post, "https://gitlab.com/api/v3/projects/k0nserv/danger-test/merge_requests/593728/notes").with(
          body: "body=#{ERB::Util.url_encode(body)}",
          headers: expected_headers
        ).to_return(status: 200, body: "", headers: {})
        g.update_pull_request!(
          warnings: violations(["Test warning"]),
          errors: violations(["Test error"]),
          messages: violations(["Test message"])
        )
      end
    end
  end
end
