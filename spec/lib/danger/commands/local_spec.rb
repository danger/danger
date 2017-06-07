require "danger/commands/local"
require "open3"

RSpec.describe Danger::Local do
  context "prints help" do
    it "danger local --help flag prints help" do
      stdout, = Open3.capture3("danger local -h")
      expect(stdout).to include "Usage"
    end

    it "danger local -h prints help" do
      stdout, = Open3.capture3("danger local -h")
      expect(stdout).to include "Usage"
    end
  end

  describe ".options" do
    it "contains extra options for local command" do
      result = described_class.options

      expect(result).to include ["--use-merged-pr=[#id]", "The ID of an already merged PR inside your history to use as a reference for the local run."]
      expect(result).to include ["--clear-http-cache", "Clear the local http cache before running Danger locally."]
      expect(result).to include ["--pry", "Drop into a Pry shell after evaluating the Dangerfile."]
    end
  end

  context "default options" do
    it "pr number is nil and clear_http_cache defaults to false" do
      argv = CLAide::ARGV.new([])

      result = described_class.new(argv)

      expect(result.instance_variable_get(:"@pr_num")).to eq nil
      expect(result.instance_variable_get(:"@clear_http_cache")).to eq false
    end
  end

  describe "#run" do
    it "uses the local git ci source and GitHub by default" do
      host = ENV.fetch("DANGER_GITHUB_API_HOST") do
        ENV.fetch("DANGER_GITHUB_API_BASE_URL") { "https://api.github.com" }
      end

      stub_request(:get, "#{host}/repos/danger/danger/pulls/717")
        .to_return(
          :status => 200,
          :body => fixture("github_api/pr_response_717"),
          :headers => { "content-type" => "application/json" }
        )

      stub_request(:get, "https://api.github.com/repos/danger/danger/issues/717")
        .to_return(
          :status => 200,
          :body => fixture("github_api/issue_response"),
          :headers => { "content-type" => "application/json" }
        )

      stub_request(:get, "#{host}/repos/danger/danger/pulls/717/reviews?per_page=100")
        .with(:headers => {"Accept"=>"application/vnd.github.black-cat-preview+json"})
        .to_return(
          :status => 200,
          :body => fixture("github_api/pr_reviews_response"),
          :headers => { "content-type" => "application/json" }
        )
      stub_request(:get, /#{Regexp.quote(host)}\/orgs\/danger\/members\/\w*/).
        to_return(:status => 200, :body => "{\"message\": \"User does not exist or is not a public member of the organization\",
  \"documentation_url\": \"https://developer.github.com/v3/orgs/members/#check-public-membership\"}", :headers => {"content-type"=> "application/json"})

      stub_request(:get, "https://rubygems.org/api/v1/versions/danger/latest.json")
        .to_return(:status => 200, :body => "{\"version\":\"4.2.1\"}")

      expect do
        described_class
          .new(CLAide::ARGV.new(["--use-merged-pr=717"]))
          .run
      end.to output(/your mom/).to_stdout
    end
  end
end
