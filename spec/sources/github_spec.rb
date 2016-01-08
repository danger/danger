# coding: utf-8
require 'rest'
require 'spec_helper'
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
  describe "valid server response" do
    before do
      gh_env = { "DANGER_GITHUB_API_TOKEN" => "hi" }
      @g = Danger::GitHub.new(stub_ci, gh_env)

      response = JSON.parse(fixture("pr_response"), symbolize_names: true)
      allow(@g.client).to receive(:pull_request).with("artsy/eigen", "800").and_return(response)
    end

    it 'sets its pr_json' do
      @g.fetch_details
      expect(@g.pr_json).to be_truthy
    end

    it 'sets the right commit sha' do
      @g.fetch_details

      expect(@g.pr_json[:base][:sha]).to eql("704dc55988c6996f69b6873c2424be7d1de67bbe")
      expect(@g.pr_json[:head][:sha]).to eql(@g.latest_pr_commit_ref)
    end

    describe "#generate_comment" do
      before do
        @date = Time.now.strftime("%Y-%m-%d")
      end

      it "no warnings, no errors" do
        result = @g.generate_comment(warnings: [], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          ":white_check_mark:|Noerrorsfound-------------|------------:white_check_mark:|Nowarningsfound-------------|------------<palign=\"right\">Generatedby:no_entry_sign:danger</p>"
        )
      end

      it "some warnings, no errors" do
        result = @g.generate_comment(warnings: ["my warning", "second warning"], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          ":white_check_mark:|Noerrorsfound-------------|------------&nbsp;|2Warnings-------------|------------:warning:|mywarning:warning:|secondwarning<palign=\"right\">Generatedby:no_entry_sign:danger</p>"
        )
      end

      it "some warnings, some errors" do
        result = @g.generate_comment(warnings: ["my warning"], errors: ["some error"], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          "&nbsp;|1Error-------------|------------:no_entry_sign:|someerror&nbsp;|1Warning-------------|------------:warning:|mywarning<palign=\"right\">Generatedby:no_entry_sign:danger</p>"
        )
      end
    end

    describe "status message" do
      it "Shows a success message when no errors/warnings" do
        message = @g.generate_github_description(warnings: [], errors:[])
        expect(message).to eq("Everything is good.")
      end
      it "Shows an error messages when there are errors" do
        message = @g.generate_github_description(warnings: [1,2,3], errors:[])
        expect(message).to eq("⚠ 3 Warnings. Everything is fixable.")
      end
      it "Shows an error message when errors and warnings" do
        message = @g.generate_github_description(warnings: [1,2], errors:[1,2,3])
        expect(message).to eq("⚠ 3 Errors. 2 Warnings. Everything is fixable.")
      end
    end
  end
end
