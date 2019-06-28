# coding: utf-8

require "erb"

require "danger/request_sources/local_only"

RSpec.describe Danger::RequestSources::LocalOnly, host: :local do
  let(:ci) { instance_double("Danger::LocalOnlyGitRepo", base_commit: "origin/master", head_commit: "feature_branch") }
  let(:subject) { described_class.new(ci, {}) }

  describe "validation" do
    it "validates as an API source" do
      expect(subject.validates_as_api_source?).to be_truthy
    end

    it "validates as CI" do
      expect(subject.validates_as_ci?).to be_truthy
    end
  end

  describe "scm" do
    it "Sets up the scm" do
      expect(subject.scm).to be_kind_of(Danger::GitRepo)
    end
  end

  describe "#setup_danger_branches" do
    before do
      allow(subject.scm).to receive(:exec).and_return("found_some")
    end

    context "when specified head is missing" do
      before { expect(subject.scm).to receive(:exec).and_return("") }

      it "raises an error" do
        expect { subject.setup_danger_branches } .to raise_error("Specified commit 'origin/master' not found")
      end
    end

    it "sets danger_head to feature_branch" do
      expect(subject.scm).to receive(:exec).with(/^branch.*head.*feature_branch/).and_return("feature_branch")
      subject.setup_danger_branches
    end

    it "sets danger_base to origin/master" do
      expect(subject.scm).to receive(:exec).with(%r{^branch.*base.*origin/master}).and_return("origin/master")
      subject.setup_danger_branches
    end
  end
end
