# coding: utf-8

require "danger/request_sources/bitbucket_server"

RSpec.describe Danger::RequestSources::CodeInsightsAPI, host: :bitbucket_server do
  let(:code_insights) {
    code_insights_fields = {
      "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_KEY" => "ReportKey",
      "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_TITLE" => "Code Insights Report Title",
      "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_DESCRIPTION" => "Report description",
      "DANGER_BITBUCKETSERVER_CODE_INSIGHTS_REPORT_LOGO_URL" => "https://stash.example.com/logo_url.png"
    }
    stub_env_with_code_insights_fields = stub_env.merge(code_insights_fields)
    Danger::RequestSources::CodeInsightsAPI.new("danger", "danger", stub_env_with_code_insights_fields)}

  describe "initialization" do
    it "should properly parse corresponding environment variables" do
      expect(code_insights.username).to eq("a.name")
      expect(code_insights.password).to eq("a_password")
      expect(code_insights.host).to eq("stash.example.com")
      expect(code_insights.report_key).to eq("ReportKey")
      expect(code_insights.report_title).to eq("Code Insights Report Title")
      expect(code_insights.report_description).to eq("Report description")
      expect(code_insights.logo_url).to eq("https://stash.example.com/logo_url.png")
    end
  end

  describe "#is_ready" do
    it "should return true when all required fields are provided" do
      expect(code_insights.ready?).to be true
    end
    it "should return false when username is empty" do
      code_insights.username = ""
      expect(code_insights.ready?).to be false
    end
    it "should return false when password is empty" do
      code_insights.password = ""
      expect(code_insights.ready?).to be false
    end
    it "should return false when host is empty" do
      code_insights.host = ""
      expect(code_insights.ready?).to be false
    end
    it "should return false when report title is empty" do
      code_insights.report_title = ""
      expect(code_insights.ready?).to be false
    end
    it "should return false when report description is empty" do
      code_insights.report_description = ""
      expect(code_insights.ready?).to be false
    end
    it "should return false when report key is empty" do
      code_insights.report_key = ""
      expect(code_insights.ready?).to be false
    end
  end

  describe "#inspect" do
    it "should mask password on inspect" do
      allow(ENV).to receive(:[]).with("ENVDANGER_BITBUCKETSERVER_PASSWORD") { "supertopsecret" }
      api = described_class.new("danger", "danger", stub_env)
      inspected = api.inspect
      expect(inspected).to include(%(@password="********"))
    end
  end

end
