# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitHub::GitHubInlineCommentHandler do
  let(:ci_source) { double("ci_source", repo_slug: "owner/repo", pull_request_id: 123) }
  let(:client) { double("client") }
  let(:context) { instance_double(Danger::RequestSources::GitHub, ci_source: ci_source, client: client) }
  let(:options) { { danger_id: "danger", markdowns: [] } }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitHub).and_return(true)
  end

  it "deletes stale inline comments when nothing is inline any more" do
    stale = { "id" => 7, "path" => "a.rb", "position" => 1, "commit_id" => "c", "body" => '"generated_by_danger"' }
    allow(client).to receive(:pull_request_comments).and_return([stale])

    expect(client).to receive(:delete_pull_request_comment).with("owner/repo", 7)

    described_class.new(context, { warnings: [], errors: [], messages: [] }, **options).execute
  end

  it "uses emoji shortcodes in the inline comment body" do
    allow(client).to receive(:pull_request_comments).and_return([])
    allow(context).to receive(:pr_diff).and_return(double(lines: ["+++ b/a.rb\n", "@@ -1,1 +1,1 @@\n", "+x\n"]))
    allow(context).to receive_messages(pr_json: { "head" => { "sha" => "c" } }, dismiss_out_of_range_messages: false)
    error = Danger::Violation.new("boom", false, "a.rb", 1)

    expect(client).to receive(:create_pull_request_comment) do |_slug, _id, body, *_rest|
      expect(body).to include(":no_entry_sign:")
    end

    described_class.new(context, { warnings: [], errors: [error], messages: [] }, **options).execute
  end
end
