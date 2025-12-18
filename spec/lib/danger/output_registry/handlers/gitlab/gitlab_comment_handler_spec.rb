# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitLab::GitLabCommentHandler do
  let(:ci_source) { double("ci_source", repo_slug: "owner/repo", pull_request_id: 123) }
  let(:client) { double("client") }
  let(:context) do
    instance_double(
      Danger::RequestSources::GitLab,
      ci_source: ci_source,
      client: client
    )
  end

  let(:warning) { Danger::Violation.new("Warning message", false) }
  let(:error) { Danger::Violation.new("Error message", false) }
  let(:inline_warning) { Danger::Violation.new("Inline warning", false, "file.rb", 10) }
  let(:markdown) { Danger::Markdown.new("Some markdown") }
  let(:inline_markdown) { Danger::Markdown.new("Inline markdown", "file.rb", 10) }

  let(:violations) do
    {
      warnings: [warning, inline_warning],
      errors: [error],
      messages: []
    }
  end

  let(:options) do
    {
      danger_id: "danger",
      new_comment: false,
      remove_previous_comments: false,
      markdowns: [markdown, inline_markdown]
    }
  end

  subject(:handler) { described_class.new(context, violations, **options) }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitLab).and_return(true)
  end

  describe "#execute" do
    context "when context is not GitLab" do
      before do
        allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitLab).and_return(false)
      end

      it "returns early without doing anything" do
        expect(context).not_to receive(:mr_comments)
        handler.execute
      end
    end

    context "when there are violations" do
      let(:existing_comment) { double("comment", id: 1, body: "old body") }

      before do
        allow(context).to receive(:mr_comments).and_return([existing_comment])
        allow(existing_comment).to receive(:generated_by_danger?).with("danger").and_return(true)
        allow(existing_comment).to receive(:inline?).and_return(false)
        allow(context).to receive(:parse_comment).and_return({})
        allow(context).to receive(:generate_comment).and_return("Generated comment body")
      end

      it "updates existing comment" do
        expect(client).to receive(:edit_merge_request_note).with("owner/repo", 123, 1, "Generated comment body")
        handler.execute
      end

      it "generates comment with filtered violations" do
        expect(context).to receive(:generate_comment).with(
          hash_including(
            warnings: [warning],
            errors: [error],
            messages: [],
            markdowns: [markdown]
          )
        ).and_return("Generated comment body")
        allow(client).to receive(:edit_merge_request_note)

        handler.execute
      end
    end

    context "when new_comment option is true" do
      let(:options) { super().merge(new_comment: true) }

      before do
        allow(context).to receive(:mr_comments).and_return([])
        allow(context).to receive(:generate_comment).and_return("Generated comment body")
      end

      it "creates a new comment" do
        expect(client).to receive(:create_merge_request_note).with("owner/repo", 123, "Generated comment body")
        handler.execute
      end
    end

    context "when no existing comments" do
      before do
        allow(context).to receive(:mr_comments).and_return([])
        allow(context).to receive(:generate_comment).and_return("Generated comment body")
      end

      it "creates a new comment" do
        expect(client).to receive(:create_merge_request_note).with("owner/repo", 123, "Generated comment body")
        handler.execute
      end
    end

    context "when remove_previous_comments is true" do
      let(:options) { super().merge(remove_previous_comments: true) }

      before do
        allow(context).to receive(:mr_comments).and_return([])
        allow(context).to receive(:delete_old_comments!).with(danger_id: "danger")
        allow(context).to receive(:generate_comment).and_return("Generated comment body")
      end

      it "deletes old comments and creates new" do
        expect(context).to receive(:delete_old_comments!).with(danger_id: "danger")
        expect(client).to receive(:create_merge_request_note).with("owner/repo", 123, "Generated comment body")
        handler.execute
      end
    end

    context "when no violations to post" do
      let(:violations) { { warnings: [], errors: [], messages: [] } }
      let(:options) { super().merge(markdowns: []) }
      let(:old_comment) { double("old_comment", id: 1, body: "old") }

      before do
        allow(context).to receive(:mr_comments).and_return([old_comment])
        allow(old_comment).to receive(:generated_by_danger?).with("danger").and_return(true)
        allow(old_comment).to receive(:inline?).and_return(false)
        allow(context).to receive(:parse_comment).and_return({})
        allow(context).to receive(:delete_old_comments!).with(danger_id: "danger")
      end

      it "deletes old comments when they exist" do
        expect(context).to receive(:delete_old_comments!).with(danger_id: "danger")
        handler.execute
      end
    end
  end

  describe "#filter_comment_violations" do
    it "excludes inline violations" do
      result = handler.send(:filter_comment_violations)

      expect(result[:warnings]).to eq([warning])
      expect(result[:warnings]).not_to include(inline_warning)
    end

    it "includes non-inline violations" do
      result = handler.send(:filter_comment_violations)

      expect(result[:errors]).to eq([error])
    end
  end

  describe "#filter_comment_markdowns" do
    it "excludes inline markdowns" do
      result = handler.send(:filter_comment_markdowns)

      expect(result).to eq([markdown])
      expect(result).not_to include(inline_markdown)
    end
  end
end
