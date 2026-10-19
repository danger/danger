# frozen_string_literal: true

require "danger/request_sources/bitbucket_server"

RSpec.describe Danger::RequestSources::BitbucketServer, host: :bitbucket_server do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketServer.new(stub_ci, env) }

  describe "#new" do
    it "should not raise uninitialized constant error" do
      expect { described_class.new(stub_ci, env) }.not_to raise_error
    end
  end

  describe "#host" do
    it "sets the host specified by `DANGER_BITBUCKETSERVER_HOST`" do
      expect(bs.host).to eq("https://stash.example.com")
    end
  end

  describe "#validates_as_api_source" do
    it "validates_as_api_source for non empty `DANGER_BITBUCKETSERVER_USERNAME` and `DANGER_BITBUCKETSERVER_PASSWORD`" do
      expect(bs.validates_as_api_source?).to be true
    end
  end

  describe "#pr_json" do
    before do
      stub_pull_request
      bs.fetch_details
    end

    it "has a non empty pr_json after `fetch_details`" do
      expect(bs.pr_json).to be_truthy
    end

    describe "#pr_json[:id]" do
      it "has fetched the same pull request id as ci_sources's `pull_request_id`" do
        expect(bs.pr_json[:id]).to eq(2080)
      end
    end

    describe "#pr_json[:title]" do
      it "has fetched the pull requests title" do
        expect(bs.pr_json[:title]).to eq("This is a danger test")
      end
    end
  end

  describe "#pr_diff" do
    it "has a non empty pr_diff after fetch" do
      stub_pull_request_diff
      bs.pr_diff
      expect(bs.pr_diff).to be_truthy
    end
  end

  describe "#main_violations_group" do
    before do
      stub_pull_request_diff
    end

    it "includes file specific messages outside the PR diff by default" do
      warning_in_diff = Danger::Violation.new("foo", false, "Gemfile", 3, type: :warning)
      warning_outside_of_diff = Danger::Violation.new("bar", false, "file.rb", 1, type: :warning)

      warnings = [
        warning_in_diff,
        warning_outside_of_diff
      ]
      expect(bs.main_violations_group(warnings: warnings)).to eq({
        warnings: [warning_outside_of_diff],
        errors: [],
        messages: [],
        markdowns: []
        })
    end

    it "dismisses messages outside the PR diff when env variable is set" do
      new_env = stub_env
      new_env.merge!({ "DANGER_BITBUCKETSERVER_DISMISS_OUT_OF_RANGE_MESSAGES" => "true" })
      inspected = Danger::RequestSources::BitbucketServer.new(stub_ci, new_env)

      warnings = [
        Danger::Violation.new("foo", false, "Gemfile", 3, type: :warning),
        Danger::Violation.new("bar", false, "file.rb", 1, type: :warning)
      ]
      expect(inspected.main_violations_group(warnings: warnings)).to eq({
        warnings: [],
        errors: [],
        messages: [],
        markdowns: []
        })
    end
  end

  describe "#find_position_in_diff" do
    before do
      stub_pull_request_diff
    end

    it "returns false when changes are not in the `pr_diff`" do
      expect(bs.find_position_in_diff?("file.rb", 1)).to be_falsy
    end

    it "returns true when changes are in included in the `pr_diff`" do
      expect(bs.find_position_in_diff?("Gemfile", 3)).to be_truthy
    end
  end

  describe "project and repo detection from the CI repo slug" do
    def bitrise_env(repo_url)
      stub_env.merge(
        "BITRISE_IO" => "true",
        "BITRISE_PULL_REQUEST" => "7",
        "GIT_REPOSITORY_URL" => repo_url,
        "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY" => "danger"
      )
    end

    def request_source_for(ci_source, environment)
      described_class.new(ci_source, environment)
    end

    def pr_api_endpoint(request_source)
      request_source.instance_variable_get(:@api).pr_api_endpoint
    end

    def code_insights_endpoint(request_source)
      request_source.instance_variable_get(:@code_insights).report_endpoint_at_commit("abc123")
    end

    {
      "https://stash.example.com/scm/proj/repo.git" => %w(proj repo),
      "https://stash.example.com/bitbucket/scm/proj/repo.git" => %w(proj repo),
      "https://stash.example.com/scm/~user/repo.git" => %w(~user repo),
      "ssh://git@stash.example.com:7999/proj/repo.git" => %w(proj repo),
      "ssh://git@stash.example.com:7999/~user/repo.git" => %w(~user repo),
      "git@stash.example.com:proj/repo.git" => %w(proj repo)
    }.each do |repo_url, (project, repo)|
      it "uses #{project}/#{repo} for the Bitrise repository URL #{repo_url}" do
        environment = bitrise_env(repo_url)
        request_source = request_source_for(Danger::Bitrise.new(environment), environment)

        expect(pr_api_endpoint(request_source)).to eq("https://stash.example.com/rest/api/1.0/projects/#{project}/repos/#{repo}/pull-requests/7")
        expect(code_insights_endpoint(request_source)).to eq("stash.example.com/rest/insights/1.0/projects/#{project}/repos/#{repo}/commits/abc123/reports/danger")
      end
    end

    it "uses the last two path segments for a Jenkins HTTPS clone URL" do
      environment = stub_env.merge("GIT_URL" => "https://stash.example.com/scm/ios/fancyapp.git")
      request_source = request_source_for(Danger::Jenkins.new(environment), environment)

      expect(pr_api_endpoint(request_source)).to eq("https://stash.example.com/rest/api/1.0/projects/ios/repos/fancyapp/pull-requests/2080")
    end

    it "keeps the previous behaviour for a slug with a single segment" do
      ci_source = double("ci_source", repo_slug: "fancyapp", pull_request_id: "2080")
      request_source = request_source_for(ci_source, stub_env)

      expect(pr_api_endpoint(request_source)).to eq("https://stash.example.com/rest/api/1.0/projects/fancyapp/repos//pull-requests/2080")
    end

    it "fetches the pull request and sets up the danger branches for a clone URL with a context path" do
      not_found = { errors: [{ message: "Project bitbucket does not exist." }] }.to_json
      WebMock.stub_request(:get, %r{\Ahttps://stash\.example\.com/rest/}).to_return(status: 404, body: not_found)
      stub_pull_request

      environment = bitrise_env("https://stash.example.com/bitbucket/scm/ios/fancyapp.git").merge("BITRISE_PULL_REQUEST" => "2080")
      request_source = request_source_for(Danger::Bitrise.new(environment), environment)

      scm = double("scm")
      allow(request_source).to receive(:scm).and_return(scm)
      allow(scm).to receive(:ensure_commitish_exists_on_branch!)
      expect(scm).to receive(:exec).with("branch danger_base b366c9564ad57786f0e5c6b8333c7aa1e2e90b9a")
      expect(scm).to receive(:exec).with("branch danger_head c50b3f61e90dac6a00b7d0c92e415a4348bb280a")

      request_source.fetch_details
      expect { request_source.setup_danger_branches }.not_to raise_error
      expect(request_source.pr_json[:id]).to eq(2080)
    end
  end
end
