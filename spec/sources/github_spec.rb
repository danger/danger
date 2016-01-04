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
      @g = Danger::GitHub.new(stub_ci)
      response = double("response", ok?: true, body: fixture("pr_response"))
      allow(REST).to receive(:get) { response }
    end

    it 'sets its pr_json' do
      @g.fetch_details
      expect(@g.pr_json).to be_truthy
    end

    it 'sets the right commit sha' do
      @g.fetch_details

      expect(@g.pr_json['base']['sha']).to eql("704dc55988c6996f69b6873c2424be7d1de67bbe")
      expect(@g.pr_json['head']['sha']).to eql(@g.latest_pr_commit_ref)
    end

    describe "#generate_comment" do
      before do
        @date = Time.now.strftime("%Y-%m-%d")
      end

      it "no warnings, no errors" do
        result = @g.generate_comment(warnings: [], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          ":white_check_mark:Noerrorsfound:white_check_mark:Nowarningsfound<palign=\"right\">Generatedby<ahref=\"https://github.com/KrauseFx/danger\">danger</a>on<i>#{@date}</i></p>"
        )
      end

      it "some warnings, no errors" do
        result = @g.generate_comment(warnings: ["my warning", "second warning"], errors: [], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          ":white_check_mark:Noerrorsfound&nbsp;|2Warnings-------------|------------:warning:|mywarning:warning:|secondwarning<palign=\"right\">Generatedby<ahref=\"https://github.com/KrauseFx/danger\">danger</a>on<i>#{@date}</i></p>"
        )
      end

      it "some warnings, some errors" do
        result = @g.generate_comment(warnings: ["my warning"], errors: ["some error"], messages: [])
        expect(result.gsub(/\s+/, "")).to eq(
          "&nbsp;|1Error-------------|------------:no_entry_sign:|someerror&nbsp;|1Warning-------------|------------:warning:|mywarning<palign=\"right\">Generatedby<ahref=\"https://github.com/KrauseFx/danger\">danger</a>on<i>#{@date}</i></p>"
        )
      end
    end
  end
end
