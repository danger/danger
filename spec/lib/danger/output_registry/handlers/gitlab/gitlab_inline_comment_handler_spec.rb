# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitLab::GitLabInlineCommentHandler do
  let(:context) { instance_double(Danger::RequestSources::GitLab, supports_inline_comments: false) }
  let(:shared_state) { { out_of_range_violations: { warnings: [], errors: [], messages: [] }, out_of_range_markdowns: [] } }
  let(:inline_error) { Danger::Violation.new("boom", false, "a.rb", 1) }
  let(:inline_markdown) { Danger::Markdown.new("md", "a.rb", 1) }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitLab).and_return(true)
  end

  it "hands inline violations to the main comment when inline comments are unsupported" do
    handler = described_class.new(
      context, { warnings: [], errors: [inline_error], messages: [] },
      danger_id: "danger", markdowns: [inline_markdown], shared_state: shared_state
    )

    handler.execute

    expect(shared_state[:out_of_range_violations][:errors]).to eq([inline_error])
    expect(shared_state[:out_of_range_markdowns]).to eq([inline_markdown])
  end
end
